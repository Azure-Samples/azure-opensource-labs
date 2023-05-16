//go:build mage

package main

import (
	"bufio"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"strings"
	"time"

	"github.com/magefile/mage/mg"
	"github.com/magefile/mage/sh"
)

// VM creates the Azure VM via the CLI (az vm create)
func VM() error {
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
	vmImage := os.Getenv("VM_IMAGE")
	if vmImage == "" {
		//vmImageGen1 := "MicrosoftCBLMariner:cbl-mariner:cbl-mariner-2:latest"
		vmImageGen2 := "MicrosoftCBLMariner:cbl-mariner:cbl-mariner-2-gen2:latest"
		//vmImageARM := "MicrosoftCBLMariner:cbl-mariner:cbl-mariner-2-arm64:latest"
		vmImage = vmImageGen2
	}
	vmOsDiskSize := os.Getenv("VM_OS_DISK_SIZE")
	if vmOsDiskSize == "" {
		vmOsDiskSize = "32"
	}
	sshKeyName := os.Getenv("SSH_KEY_NAME")
	if sshKeyName == "" {
		sshKeyName = "sshkey1"
	}

	cmd := []string{
		"az",
		"vm",
		"create",
		"--resource-group",
		name,
		"--name",
		vmName,
		"--image",
		vmImage,
		"--admin-username",
		"azureuser",
		"--generate-ssh-keys",
		"--public-ip-sku",
		"Standard",
		"--size",
		vmSize,
		"--os-disk-size-gb",
		vmOsDiskSize,
		//"--ssh-key-name",
		//sshKeyName,
	}
	return sh.RunV(cmd[0], cmd[1:]...)
}

// DockerTailcale installs Docker and runs Tailscale on the VM
func DockerTailcale() error {
	name := resourceGroup()
	vmName := os.Getenv("VM_NAME")
	if vmName == "" {
		vmName = "vm1"
	}

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
	}

	if val := os.Getenv("VM_COMMAND"); val != "" {
		cmd = append(cmd, val)
	}

	cmdDocker := []string{
		"sudo tdnf install moby-engine moby-cli ca-certificates -y",
		"sudo systemctl enable docker.service",
		"sudo systemctl daemon-reload",
		"sudo systemctl start docker.service",
	}
	cmd = append(cmd, cmdDocker...)

	tsAuthKey := os.Getenv("TS_AUTHKEY")
	if tsAuthKey == "" {
		fmt.Println("TS_AUTHKEY not set")
	}
	// example command:
	// export TS_AUTHKEY='...'
	// docker run -d --name=tailscaled -v /var/lib:/var/lib -v /dev/net/tun:/dev/net/tun --network=host --cap-add=NET_ADMIN --cap-add=NET_RAW --env TS_STATE_DIR=/var/lib/tailscale/state --env TS_AUTHKEY tailscale/tailscale
	dockerCommand := "docker run -d --name=tailscaled -v /var/lib:/var/lib -v /dev/net/tun:/dev/net/tun --network=host --cap-add=NET_ADMIN --cap-add=NET_RAW --env TS_STATE_DIR=/var/lib/tailscale/state --env TS_AUTHKEY --env TS_EXTRA_ARGS='--hostname=%s' tailscale/tailscale"
	machineName := name + "-" + vmName
	dockerCommand = fmt.Sprintf(dockerCommand, machineName)
	cmdTailscale := []string{
		"docker rm -f tailscaled",
		"sudo rm -rf /var/lib/tailscale/",
		"export TS_AUTHKEY=" + fmt.Sprintf("'%s'", tsAuthKey),
		dockerCommand,
	}
	if tsAuthKey != "" {
		cmd = append(cmd, cmdTailscale...)
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

// RunScript runs an optional command (VM_COMMAND) followed by script (VM_SCRIPT) using RunCommand on the Azure VM
func RunScript() error {
	name := resourceGroup()
	vmName := os.Getenv("VM_NAME")
	if vmName == "" {
		vmName = "vm1"
	}

	var cmdScript []string

	vmCommand := os.Getenv("VM_COMMAND")
	switch {
	case vmCommand == "":
		fmt.Printf("VM_COMMAND not set. Skipping.\n")
	case vmCommand != "":
		fmt.Printf("VM_COMMAND was set.\n")
		cmdScript = append(cmdScript, vmCommand)
	}

	vmScript := os.Getenv("VM_SCRIPT")
	if vmScript == "" {
		return errors.New("VM_SCRIPT not set")
	}

	file, err := os.Open(vmScript)
	if err != nil {
		return err
	}
	defer file.Close()
	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		cmdScript = append(cmdScript, scanner.Text())
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

// ManagedIdentity creates a managed identity for the Azure VM
func ManagedIdentity() error {
	name := resourceGroup()
	vmName := os.Getenv("VM_NAME")
	if vmName == "" {
		vmName = "vm1"
	}

	identityName := name + "-identity"

	cmd := []string{
		"az",
		"identity",
		"create",
		"--resource-group",
		name,
		"--name",
		identityName,
	}
	err := sh.RunV(cmd[0], cmd[1:]...)
	if err != nil {
		return err
	}

	cmd = []string{
		"az",
		"vm",
		"identity",
		"assign",
		"--resource-group",
		name,
		"--name",
		vmName,
		"--identities",
		identityName,
	}
	return sh.RunV(cmd[0], cmd[1:]...)
}

// SshKey creates an ssh key for Azure VMs
func SshKey() error {
	name := resourceGroup()
	sshKeyName := os.Getenv("SSH_KEY_NAME")
	if sshKeyName == "" {
		sshKeyName = "sshkey1"
	}

	cmd := []string{
		"az",
		"sshkey",
		"create",
		"--name",
		sshKeyName,
		"--resource-group",
		name,
	}
	return sh.RunV(cmd[0], cmd[1:]...)
}

// VmBicep deploys vm.bicep to the Azure resource group with parameters
func VmBicep() error {
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

	file1 := "vm.bicep"
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

// whoAmI returns our public IP, currently shelling out to dig
func whoAmI() (string, error) {
	res, err := sh.Output(
		"dig",
		"@1.1.1.1",
		"ch",
		"txt",
		"whoami.cloudflare",
		"+short",
	)
	if err != nil {
		return "", err
	}
	res = strings.ReplaceAll(res, "\"", "")
	return res, nil
}

// SSH gets the FQDN of the VM and outputs an ssh command
func SSH() error {
	name := resourceGroup()
	location := os.Getenv("LOCATION")
	if location == "" {
		location = "eastus"
	}
	vmName := os.Getenv("VM_NAME")
	if vmName == "" {
		vmName = "vm1"
	}

	cmd := []string{
		"az",
		"vm",
		"show",
		"--resource-group",
		name,
		"--name",
		vmName,
		"--show-details",
		"--query",
		"fqdns",
		"--output",
		"tsv",
	}

	fqdns, err := sh.Output(cmd[0], cmd[1:]...)
	if err != nil {
		return err
	}
	if fqdns == "" {
		return errors.New("fqdns is empty")
	}

	fmt.Printf("ssh azureuser@%s\n", fqdns)
	return nil
}

type Group mg.Namespace

func resourceGroup() string {
	name := os.Getenv("RESOURCE_GROUP")
	if name == "" {
		name = fmt.Sprintf("%s-mariner", time.Now().Format("060100"))
	}
	return name
}

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

// Subscription switches between two Azure subscriptions
func Subscription() error {
	sub1 := os.Getenv("SUB1")
	sub2 := os.Getenv("SUB2")
	if sub1 == "" || sub2 == "" {
		return errors.New("SUB1 and SUB2 must be set")
	}

	cmd := []string{
		"az",
		"account",
		"show",
		"--query",
		"name",
		"--out",
		"tsv",
	}
	sub, err := sh.Output(cmd[0], cmd[1:]...)
	if err != nil {
		return err
	}

	switch sub {
	case sub1:
		sub = sub2
	case sub2:
		sub = sub1
	default:
		sub = sub1
	}

	cmd = []string{
		"az",
		"account",
		"set",
		"--subscription",
		sub,
	}
	fmt.Printf("Switching to subscription %s\n", sub)
	return sh.RunV(cmd[0], cmd[1:]...)
}
