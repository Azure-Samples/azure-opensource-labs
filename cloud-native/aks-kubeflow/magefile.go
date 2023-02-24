//go:build mage

package main

import (
	"errors"
	"fmt"
	"io"
	"net/http"
	"os"
	"runtime"
	"strings"
	"time"

	"golang.org/x/crypto/bcrypt"

	"github.com/magefile/mage/mg"
	"github.com/magefile/mage/sh"
	"github.com/sethvargo/go-password/password"
)

// Group creates the Azure resource group
func Group() error {
	name := os.Getenv("RESOURCE_GROUP")
	if name == "" {
		name = fmt.Sprintf("%s-kubeflow", time.Now().Format("060100"))
	}
	location := os.Getenv("LOCATION")
	if location == "" {
		location = "eastus"
	}
	cmd := []string{
		"az",
		"group",
		"create",
		"--name",
		name,
		"--location",
		location,
	}
	return sh.RunV(cmd[0], cmd[1:]...)
}

// Aks creates the Azure Kubernetes Service (AKS) cluster
func Aks() error {
	name := os.Getenv("RESOURCE_GROUP")
	if name == "" {
		name = fmt.Sprintf("%s-kubeflow", time.Now().Format("060100"))
	}
	aksName := os.Getenv("AKS_NAME")
	if aksName == "" {
		aksName = "aks1"
	}
	nodeVmSize := os.Getenv("AKS_VM_SIZE")
	if nodeVmSize == "" {
		nodeVmSize = "Standard_D2s_v5"
	}
	nodeCount := os.Getenv("AKS_NODE_COUNT")
	if nodeCount == "" {
		nodeCount = "3"
	}
	kubernetesVersion := os.Getenv("AKS_KUBERNETES_VERSION")
	if kubernetesVersion == "" {
		kubernetesVersion = "1.24.9"
	}
	cmd := []string{
		"az",
		"aks",
		"create",
		"--resource-group",
		name,
		"--name",
		aksName,
		"--node-count",
		nodeCount,
		"--node-vm-size",
		nodeVmSize,
		"--kubernetes-version",
		kubernetesVersion,
		"--enable-addons",
		"monitoring",
		"--generate-ssh-keys",
	}
	return sh.RunV(cmd[0], cmd[1:]...)
}

// AksCredentials gets credentials for the AKS cluster
func AksCredentials() error {
	name := os.Getenv("RESOURCE_GROUP")
	if name == "" {
		name = fmt.Sprintf("%s-kubeflow", time.Now().Format("060100"))
	}
	aksName := os.Getenv("AKS_NAME")
	if aksName == "" {
		aksName = "aks1"
	}
	cmd := []string{
		"az",
		"aks",
		"get-credentials",
		"--resource-group",
		name,
		"--name",
		aksName,
		"--overwrite-existing",
	}
	return sh.RunV(cmd[0], cmd[1:]...)
}

// AksKubectl ensures kubectl is installed
func AksKubectl() error {
	cmd := []string{
		"az",
		"aks",
		"install-cli",
	}
	return sh.RunV(cmd[0], cmd[1:]...)
}

// EnsureKustomize downloads kustomize from GitHub
func EnsureKustomize() error {
	if os.Getenv("SUDO_USER") == "" {
		return errors.New("run this command with sudo")
	}
	switch {
	case runtime.GOOS == "darwin" && (runtime.GOARCH == "arm64" || runtime.GOARCH == "amd64"):
		// note: 3.2.0 only has amd64 builds so we use this, and will require rosetta
		url1 := "https://github.com/kubernetes-sigs/kustomize/releases/download/v3.2.0/kustomize_3.2.0_darwin_amd64"
		res, err := http.Get(url1)
		if err != nil {
			return err
		}
		defer res.Body.Close()
		file1 := "/usr/local/bin/kustomize"
		f, err := os.OpenFile(file1, os.O_CREATE|os.O_RDWR|os.O_TRUNC, 0755)
		if err != nil {
			return err
		}
		defer f.Close()
		_, err = io.Copy(f, res.Body)
		if err != nil {
			return err
		}

	case runtime.GOOS == "linux" && runtime.GOARCH == "amd64":
		url1 := "https://github.com/kubernetes-sigs/kustomize/releases/download/v3.2.0/kustomize_3.2.0_linux_amd64"
		res, err := http.Get(url1)
		if err != nil {
			return err
		}
		defer res.Body.Close()
		file1 := "/usr/local/bin/butane"
		f, err := os.OpenFile(file1, os.O_RDWR|os.O_TRUNC, 0755)
		if err != nil {
			return err
		}
		defer f.Close()
		_, err = io.Copy(f, res.Body)
		if err != nil {
			return err
		}

	default:
		return fmt.Errorf("GOOS: %s GOARCH: %s not implemented", runtime.GOOS, runtime.GOARCH)

	}
	return nil
}

// Kubeflow installs kubeflow from the manifests
func Kubeflow() error {
	dir1 := "manifests"
	os.Chdir(dir1)
	defer os.Chdir("..")

	installCommand := "while ! kustomize build example | kubectl apply -f -; do echo \"Retrying to apply resources\"; sleep 10; done"
	cmd := []string{
		"bash",
		"-c",
		installCommand,
	}
	return sh.RunV(cmd[0], cmd[1:]...)
}

// KubeflowDelete deletes kubeflow from the manifests
func KubeflowDelete() error {
	dir1 := "manifests"
	os.Chdir(dir1)
	defer os.Chdir("..")

	installCommand := "kustomize build example | kubectl delete -f -"
	cmd := []string{
		"bash",
		"-c",
		installCommand,
	}
	return sh.RunV(cmd[0], cmd[1:]...)
}

// KubectlReady checks that all pods are ready
func KubectlReady() error {
	namespaces := []string{
		"cert-manager",
		"istio-system",
		"auth",
		"knative-eventing",
		"knative-serving",
		"kubeflow",
		"kubeflow-user-example-com",
	}
	checkReady := func() error {
		for _, namespace := range namespaces {
			cmd := []string{
				"kubectl",
				"wait",
				"--for=condition=Ready",
				"pods",
				"--all",
				"--namespace",
				namespace,
				"--timeout=30s",
			}
			err := sh.RunV(cmd[0], cmd[1:]...)
			if err != nil {
				return err
			}
		}
		return nil
	}

	maxAttempts := 10
	waitSecs := 60
	for i := 1; i <= maxAttempts; i++ {
		err := checkReady()
		if err != nil {
			fmt.Printf("%s\n", err)
			if i < maxAttempts {
				fmt.Printf("attempt %d of %d failed. waiting %d seconds.\n", i, maxAttempts, waitSecs)
				time.Sleep(time.Duration(waitSecs) * time.Second)
			}
			continue
		}
		return nil
	}
	return fmt.Errorf("exceeded maxAttempts: %d", maxAttempts)
}

// KubeflowPods returns all Kubeflow pods
func KubeflowPods() error {
	commands := []string{
		"kubectl get pods -n cert-manager",
		"kubectl get pods -n istio-system",
		"kubectl get pods -n auth",
		"kubectl get pods -n knative-eventing",
		"kubectl get pods -n knative-serving",
		"kubectl get pods -n kubeflow",
		"kubectl get pods -n kubeflow-user-example-com",
	}
	for _, x := range commands {
		cmd := strings.Split(x, " ")
		err := sh.RunV(cmd[0], cmd[1:]...)
		if err != nil {
			return err
		}
	}
	return nil
}

// KubeflowPort port forwards to Kubeflow
func KubeflowPort() error {
	cmd := []string{
		"kubectl",
		"port-forward",
		"svc/istio-ingressgateway",
		"-n",
		"istio-system",
		"8080:80",
	}
	return sh.RunV(cmd[0], cmd[1:]...)
}

// RestartDex restarts dex
func RestartDex() error {
	cmd := []string{
		"kubectl",
		"rollout",
		"restart",
		"deployment",
		"dex",
		"-n",
		"auth",
	}
	return sh.RunV(cmd[0], cmd[1:]...)
}

// Clone clones the kubeflow/manifests at the correct version
func Clone() error {
	kubeflowVersion := os.Getenv("KUBEFLOW_VERSION")
	if kubeflowVersion == "" {
		kubeflowVersion = "v1.6.1"
	}
	return sh.RunV(
		"git",
		"clone",
		"https://github.com/kubeflow/manifests.git",
		"-b",
		kubeflowVersion,
	)
}

// Checkout checks out the git repo to overwrite changes
func Checkout() error {
	dir1 := "manifests"
	os.Chdir(dir1)
	defer os.Chdir("..")
	cmd := []string{
		"git",
		"checkout",
		".",
	}
	return sh.RunV(cmd[0], cmd[1:]...)
}

// Clean cleans up the cloned folder
func Clean() error {
	dir1 := "manifests"
	return os.RemoveAll(dir1)
}

// Empty empties the Azure resource group
func Empty() error {
	name := os.Getenv("RESOURCE_GROUP")
	if name == "" {
		name = fmt.Sprintf("%s-kubeflow", time.Now().Format("060100"))
	}
	file1 := "empty.bicep"
	f, err := os.Create(file1)
	if err != nil {
		return err
	}
	f.Close()
	cmd := []string{
		"az",
		"deployment",
		"group",
		"create",
		"--resource-group",
		name,
		"--template-file",
		file1,
		"--mode",
		"Complete",
	}
	err = sh.RunV(cmd[0], cmd[1:]...)
	if err != nil {
		return err
	}
	err = os.RemoveAll(file1)
	if err != nil {
		return err
	}
	return nil
}

// GroupDelete deletes the Azure resource group
func GroupDelete() error {
	name := os.Getenv("RESOURCE_GROUP")
	if name == "" {
		name = fmt.Sprintf("%s-kubeflow", time.Now().Format("060100"))
	}
	cmd := []string{
		"az",
		"group",
		"delete",
		"--name",
		name,
		"--yes",
	}
	return sh.RunV(cmd[0], cmd[1:]...)
}

// Password generates a password and hash and outputs it to the standard output
func Password() error {
	pass, hash, err := passwordAndHash()
	if err != nil {
		return err
	}
	fmt.Printf("Password: %s\n", pass)
	fmt.Printf("Hash: %s\n", hash)
	return nil
}

// Patch copies manifests from aks/manifests/ to manifests/
func Patch() error {
	cmd := []string{
		"cp",
		"-r",
		"aks/manifests",
		".",
	}
	return sh.RunV(cmd[0], cmd[1:]...)
}

// ConfigureDex updates the manifests prior to deployment
func ConfigureDex() error {
	// revert changes to manifest
	file1 := "aks/manifests/common/dex/base/config-map.yaml"
	cmd1 := []string{
		"git",
		"checkout",
		file1,
	}
	err := sh.RunV(cmd1[0], cmd1[1:]...)
	if err != nil {
		return err
	}

	// generate password and add hash to config-map.yaml
	pass, hash, err := passwordAndHash()
	if err != nil {
		return err
	}
	replace1 := map[string]string{
		"hash: $2y$12$4K/VkmDd1q1Orb3xAt82zu8gk7Ad6ReFR4LCP9UeYE90NLiN9Df72": "hash: " + hash,
	}
	err = fileReplace(file1, replace1)
	if err != nil {
		return err
	}

	file2 := "auth.md"
	cmd2 := []string{
		"git",
		"checkout",
		file2,
	}
	err = sh.RunV(cmd2[0], cmd2[1:]...)
	if err != nil {
		return err
	}
	replace2 := map[string]string{
		"Password: 12341234": "Password: " + pass,
	}
	err = fileReplace(file2, replace2)
	if err != nil {
		return err
	}

	return nil
}

// ConfigureTLS deploys the certificate manifest
func ConfigureTLS() error {
	// get ip address of istio-ingressgateway
	cmd1 := []string{
		"kubectl",
		"-n",
		"istio-system",
		"get",
		"service",
		"istio-ingressgateway",
		"--output",
		"jsonpath={.status.loadBalancer.ingress[0].ip}",
	}
	ip, err := sh.Output(cmd1[0], cmd1[1:]...)
	if err != nil {
		return err
	}
	if ip == "" {
		return errors.New("ip is empty")
	}
	fmt.Printf("IP Address: %s\n", ip)

	file1 := "aks/certificate.yaml"
	// revert changes to manifest
	cmd2 := []string{
		"git",
		"checkout",
		file1,
	}
	err = sh.RunV(cmd2[0], cmd2[1:]...)
	if err != nil {
		return err
	}
	// update IP address in certificate.yaml
	replace1 := map[string]string{
		"192.168.0.5": ip,
	}
	err = fileReplace(file1, replace1)
	if err != nil {
		return err
	}

	// update IP address in auth.md
	file2 := "auth.md"
	replace2 := map[string]string{
		"URL: http://localhost:8080": "URL: https://" + ip,
	}
	err = fileReplace(file2, replace2)
	if err != nil {
		return err
	}

	cmd := []string{
		"kubectl",
		"apply",
		"-f",
		"aks/certificate.yaml",
	}
	return sh.RunV(cmd[0], cmd[1:]...)
}

// Wait for the specified number of seconds
func Wait(secs int) error {
	fmt.Printf("waiting %ds\n", secs)
	time.Sleep(time.Second * time.Duration(secs))
	return nil
}

// KubeflowAll runs clean clone configuredex patch kubeflow kubectlready restartdex configuretls
func KubeflowAll() {
	mg.SerialDeps(Clean, Clone, ConfigureDex, Patch, Kubeflow, KubectlReady, RestartDex, ConfigureTLS)
}

// passwordAndHash generates a secure 32 character password and its bcrypt hash
func passwordAndHash() (string, string, error) {
	password, err := password.Generate(32, 10, 10, false, false)
	if err != nil {
		return "", "", err
	}
	cost := 12
	b, err := bcrypt.GenerateFromPassword([]byte(password), cost)
	if err != nil {
		return "", "", err
	}
	return password, string(b), nil
}

// fileReplace replaces values in a file using a map
func fileReplace(file string, replace map[string]string) error {
	b, err := os.ReadFile(file)
	if err != nil {
		return err
	}
	val := string(b)
	for k, v := range replace {
		val = strings.Replace(val, k, v, -1)
	}
	return os.WriteFile(file, []byte(val), 0644)
}
