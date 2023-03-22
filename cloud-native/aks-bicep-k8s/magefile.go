//go:build mage

package main

import (
	"errors"
	"fmt"
	"os"
	"strings"
	"time"

	"github.com/magefile/mage/sh"
)

// resourceGroup gets resource group name from the
// RESOURCE_GROUP env var, or provides a default
func resourceGroup() string {
	name := os.Getenv("RESOURCE_GROUP")
	if name == "" {
		name = fmt.Sprintf("%s-aks-bicep", time.Now().Format("060100"))
	}
	return name
}

// Group creates the Azure resource group
func Group() error {
	name := resourceGroup()
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

// DeployAKS deploys aks.bicep at the Resource Group scope
func DeployAKS() error {
	name := resourceGroup()
	location := os.Getenv("LOCATION")
	if location == "" {
		location = "eastus"
	}

	file1 := "aks.bicep"
	cmd := []string{
		"az",
		"deployment",
		"group",
		"create",
		"--resource-group",
		name,
		"--template-file",
		file1,
		"--parameters",
		"location=" + location,
	}
	return sh.RunV(cmd[0], cmd[1:]...)
}

// DeployAKS deploys azure-vote-deploy.bicep at the Resource Group scope
func DeployApp() error {
	name := resourceGroup()
	k8sNamespace := os.Getenv("K8S_NAMESPACE")
	if k8sNamespace == "" {
		k8sNamespace = "default"
	}
	file1 := "aks-deploy-app.bicep"
	cmd := []string{
		"az",
		"deployment",
		"group",
		"create",
		"--resource-group",
		name,
		"--template-file",
		file1,
		"--parameters",
		"namespace=" + k8sNamespace,
	}
	err := sh.RunV(cmd[0], cmd[1:]...)
	if err != nil {
		fmt.Printf("error. retrying once in 20s.\n")
		time.Sleep(20 * time.Second)
		err = sh.RunV(cmd[0], cmd[1:]...)
	}
	return err
}

// DeployMain [experimental] deploys main.bicep at the Resource Group scope
func DeployMain() error {
	name := resourceGroup()
	location := os.Getenv("LOCATION")
	if location == "" {
		location = "eastus"
	}
	aksName := os.Getenv("AKS_NAME")
	if aksName == "" {
		aksName = "aks1"
	}
	deployCluster := os.Getenv("DEPLOY_CLUSTER")
	if deployCluster == "" {
		deployCluster = "true"
	}
	switch {
	case deployCluster == "true" || deployCluster == "false":
	default:
		return errors.New("DEPLOY_CLUSTER must be true, false, or empty")
	}

	file1 := "main.bicep"
	cmd := []string{
		"az",
		"deployment",
		"group",
		"create",
		"--resource-group",
		name,
		"--template-file",
		file1,
		"--parameters",
		"location=" + location,
		"clusterName=" + aksName,
		"deployCluster=" + deployCluster,
	}
	return sh.RunV(cmd[0], cmd[1:]...)
}

// EmptyNamespace has az invoke kubectl delete all on K8S_NAMESPACE
func EmptyNamespace() error {
	name := resourceGroup()
	location := os.Getenv("LOCATION")
	if location == "" {
		location = "eastus"
	}
	aksName := os.Getenv("AKS_NAME")
	if aksName == "" {
		aksName = "aks1"
	}
	k8sNamespace := os.Getenv("K8S_NAMESPACE")
	if k8sNamespace == "" {
		k8sNamespace = "default"
	}

	kubectlCommand := "kubectl delete all --all -n " + k8sNamespace
	cmd := []string{
		"az",
		"aks",
		"command",
		"invoke",
		"--resource-group",
		name,
		"--name",
		aksName,
		"--command",
		kubectlCommand,
	}
	return sh.RunV(cmd[0], cmd[1:]...)
}

// AksCredentials gets credentials for the AKS cluster
func AksCredentials() error {
	name := resourceGroup()
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

// Empty empties the Azure resource group
func Empty() error {
	name := resourceGroup()
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
	name := resourceGroup()
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
