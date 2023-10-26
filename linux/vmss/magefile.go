//go:build mage

package main

import (
	"bufio"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"os"
	"strings"
	"time"

	"github.com/magefile/mage/mg"
	"github.com/magefile/mage/sh"
)

type Az mg.Namespace

// VM deploys vm.bicep
func (Az) VM() error {
	name := resourceGroup()
	location := os.Getenv("LOCATION")
	if location == "" {
		location = "eastus"
	}
	vmName := os.Getenv("VM_NAME")
	if vmName == "" {
		vmName = "vm1"
	}
	vmSize := os.Getenv("VM_SIZE")
	if vmSize == "" {
		vmSize = "Standard_B2s"
	}
	vmOsDiskSize := os.Getenv("VM_OS_DISK_SIZE")
	if vmOsDiskSize == "" {
		vmOsDiskSize = "128"
	}
	vmCustomData := os.Getenv("VM_CUSTOMDATA")
	switch vmCustomData {
	case "cloud-init":
		vmCustomData = "cloud-init"
	default:
		vmCustomData = "none"
	}

	env := os.Getenv("ENV")
	if env == "" {
		env = "{}"
	}
	tmp1 := map[string]string{}
	if err := json.Unmarshal([]byte(env), &tmp1); err != nil {
		return fmt.Errorf("ENV must be valid JSON: %s", err)
	}

	ipAllow := os.Getenv("IP_ALLOW")
	if ipAllow == "" {
		res, err := whoAmI()
		if err != nil {
			return err
		}
		ipAllow = res
	}

	sshPublicKey, err := loadSshKey(os.Getenv("SSH_KEY"))
	if err != nil {
		return err
	}

	file1 := "bicep/vm.bicep"
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
		"vmName=" + vmName,
		"vmSize=" + vmSize,
		"osDiskSize=" + vmOsDiskSize,
		"sshKey=" + sshPublicKey,
		"allowIpPort22=" + ipAllow,
		"customData=" + vmCustomData,
		"env=" + env,
	}
	return sh.RunV(cmd[0], cmd[1:]...)
}

// VMSS deploys vm.bicep
func (Az) VMSS() error {
	name := resourceGroup()
	location := os.Getenv("LOCATION")
	if location == "" {
		location = "eastus"
	}
	vmName := os.Getenv("VMSS_NAME")
	if vmName == "" {
		vmName = "vmss1"
	}
	vmSize := os.Getenv("VMSS_SIZE")
	if vmSize == "" {
		vmSize = "Standard_B2s"
	}
	vmInstanceCount := os.Getenv("VMSS_INSTANCE_COUNT")
	if vmInstanceCount == "" {
		vmInstanceCount = "0"
	}
	vmOsDiskSize := os.Getenv("VMSS_OS_DISK_SIZE")
	if vmOsDiskSize == "" {
		vmOsDiskSize = "128"
	}
	vmCustomData := os.Getenv("VMSS_CUSTOMDATA")
	switch vmCustomData {
	case "cloud-init":
		vmCustomData = "cloud-init"
	default:
		vmCustomData = "none"
	}

	env := os.Getenv("ENV")
	if env == "" {
		env = "{}"
	}
	tmp1 := map[string]string{}
	if err := json.Unmarshal([]byte(env), &tmp1); err != nil {
		return fmt.Errorf("ENV must be valid JSON: %s", err)
	}

	ipAllow := os.Getenv("IP_ALLOW")
	if ipAllow == "" {
		res, err := whoAmI()
		if err != nil {
			return err
		}
		ipAllow = res
	}

	sshPublicKey, err := loadSshKey(os.Getenv("SSH_KEY"))
	if err != nil {
		return err
	}

	file1 := "vmss.bicep"
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
		"vmssName=" + vmName,
		"adminPasswordOrKey=" + sshPublicKey,
		"vmSize=" + vmSize,
		"osDiskSize=" + vmOsDiskSize,
		//"sshKey=" + sshPublicKey,
		"allowIpPort22=" + ipAllow,
		"instanceCount=" + vmInstanceCount,
		"env=" + env,
	}
	return sh.RunV(cmd[0], cmd[1:]...)
}

// RunScripts executes RunCommand on the Azure VM
func (Az) RunScripts(vmScripts string) error {
	name := resourceGroup()
	vmName := os.Getenv("VM_NAME")
	if vmName == "" {
		vmName = "vm1"
	}

	if vmScripts == "" {
		return errors.New("vmScripts is empty")
	}

	var cmdScript []string
	scripts := strings.Split(vmScripts, ",")
	for _, vmScript := range scripts {
		file, err := os.Open(vmScript)
		if err != nil {
			return err
		}
		defer file.Close()
		scanner := bufio.NewScanner(file)
		for scanner.Scan() {
			cmdScript = append(cmdScript, scanner.Text())
		}
	}

	tmpName := "tmp.sh"
	tmpFile, err := os.OpenFile(tmpName, os.O_RDWR|os.O_CREATE|os.O_TRUNC, 0755)
	if err != nil {
		return err
	}
	defer os.Remove(tmpFile.Name())
	for _, line := range cmdScript {
		_, err := tmpFile.WriteString(line + "\n")
		if err != nil {
			return err
		}
	}
	tmpFile.Close()

	cmd := []string{
		"az",
		"vm",
		"run-command",
		"invoke",
		"--resource-group",
		name,
		"--name",
		vmName,
		"--command-id",
		"RunShellScript",
		"--scripts",
		"@" + tmpName,
	}

	output1, err := sh.Output(cmd[0], cmd[1:]...)
	if err != nil {
		return err
	}

	resp1 := struct {
		Value []struct {
			Code          string `json:"code"`
			DisplayStatus string `json:"displayStatus"`
			Level         string `json:"level"`
			Message       string `json:"message"`
			Time          string `json:"time"`
		} `json:"value"`
	}{}

	err = json.Unmarshal([]byte(output1), &resp1)
	if err != nil {
		return err
	}
	fmt.Printf("# Code: %s\n", resp1.Value[0].Code)
	fmt.Printf("# DisplayStatus: %s\n", resp1.Value[0].DisplayStatus)
	fmt.Printf("# Level: %s\n", resp1.Value[0].Level)
	fmt.Printf("# Message: \n")
	fmt.Printf("%s\n", resp1.Value[0].Message)
	return nil
}

type Group mg.Namespace

// Create creates the Azure Resource Group
func (Group) Create() error {
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

// Empty empties the Azure Resource Group
func (Group) Empty() error {
	name := resourceGroup()
	file1 := "empty.bicep"
	f, err := os.Create(file1)
	if err != nil {
		return err
	}
	f.Close()

	fmt.Printf("Emptying RESOURCE_GROUP %s in 10 seconds.\n", name)
	time.Sleep(time.Second * 10)

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

// Delete deletes the Azure Resource Group
func (Group) Delete() error {
	name := resourceGroup()
	fmt.Printf("Deleting RESOURCE_GROUP %s in 10 seconds.\n", name)
	time.Sleep(time.Second * 10)

	cmd := []string{
		"az",
		"group",
		"delete",
		"--resource-group",
		name,
		"--yes",
	}
	return sh.RunV(cmd[0], cmd[1:]...)
}

// helper functions

// resourceGroup gets resource group name from the
// RESOURCE_GROUP env var, or provides a default
func resourceGroup() string {
	name := os.Getenv("RESOURCE_GROUP")
	if name == "" {
		name = fmt.Sprintf("%s-azr", time.Now().Format("060100"))
	}
	return name
}

// loadSshKey will try to read a public ssh key from disk
// it will warn and return an empty string if provided an
// empty filename, and will throw an error if provided a
// private key
func loadSshKey(sshPublicKey string) (string, error) {
	if sshPublicKey == "" {
		fmt.Printf("SSH_KEY not set. Using default.\n")
		return "", nil
	}

	if sshPublicKey != "" {
		tmp, err := os.ReadFile(sshPublicKey)
		if err != nil {
			return "", err
		}
		sshPublicKey = string(tmp)
	}

	if strings.HasPrefix(sshPublicKey, "-----BEGIN OPENSSH PRIVATE KEY-----") {
		return "", errors.New("SSH_KEY is a private key. Provide a public key instead")
	}
	return sshPublicKey, nil
}

type Test mg.Namespace

func (Test) WhoAmI() error {
	ipAddress, err := whoAmI()
	if err != nil {
		return err
	}
	fmt.Printf("%s\n", ipAddress)
	return nil
}

// whoAmI returns our public IP, currently shelling out to dig
func whoAmI() (string, error) {
	// note: this is an opendns service
	// see: https://dnsomatic.com/
	url1 := "https://myip.dnsomatic.com/"

	req, err := http.NewRequest(http.MethodGet, url1, nil)
	if err != nil {
		return "", err
	}
	res, err := http.DefaultClient.Do(req)
	if err != nil {
		return "", err
	}
	defer res.Body.Close()
	if res.StatusCode != http.StatusOK {
		return "", fmt.Errorf("%s returned %d", url1, res.StatusCode)
	}
	b, err := io.ReadAll(res.Body)
	if err != nil {
		return "", err
	}
	return strings.TrimSpace(string(b)), nil
}
