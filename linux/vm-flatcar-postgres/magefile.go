//go:build mage

package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"os"
	"regexp"
	"runtime"
	"strings"
	"time"

	"github.com/magefile/mage/sh"
	"github.com/sethvargo/go-password/password"
)

// Group creates the Azure resource group
func Group() error {
	name := os.Getenv("RESOURCE_GROUP")
	if name == "" {
		name = fmt.Sprintf("%s-postgres", time.Now().Format("060100"))
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

// DeployMain deploys main.bicep at the Subscription level
func DeployMain() error {
	name := os.Getenv("RESOURCE_GROUP")
	if name == "" {
		name = fmt.Sprintf("%s-postgres", time.Now().Format("060100"))
	}
	location := os.Getenv("LOCATION")
	if location == "" {
		location = "eastus"
	}

	// ssh key is not required in this template but we will
	// provide it if set.
	sshPublicKey, err := loadSshKey(os.Getenv("SSH_KEY"))
	if err != nil {
		return err
	}

	// todo: add firewallRuleIp parameter
	file1 := "main.bicep"
	cmd := []string{
		"az",
		"deployment",
		"sub",
		"create",
		"--location",
		location,
		"--template-file",
		file1,
		"--parameters",
		"resourceGroup=" + name,
		"sshKey=" + sshPublicKey,
	}
	return sh.RunV(cmd[0], cmd[1:]...)
}

// TailscaleDeploy runs tailscale on the VM via docker
func TailscaleDeploy() error {
	name := os.Getenv("RESOURCE_GROUP")
	if name == "" {
		name = fmt.Sprintf("%s-postgres", time.Now().Format("060100"))
	}
	vmName := os.Getenv("VM_NAME")
	if vmName == "" {
		vmName = "vm1"
	}
	tsAuthKey := os.Getenv("TS_AUTHKEY")
	if tsAuthKey == "" {
		return errors.New("TS_AUTHKEY not set")
	}

	// example command:
	// export TS_AUTHKEY='...'
	// docker run -d --name=tailscaled -v /var/lib:/var/lib -v /dev/net/tun:/dev/net/tun --network=host --cap-add=NET_ADMIN --cap-add=NET_RAW --env TS_STATE_DIR=/var/lib/tailscale/state --env TS_AUTHKEY tailscale/tailscale

	dockerCommand := "docker run -d --name=tailscaled -v /var/lib:/var/lib -v /dev/net/tun:/dev/net/tun --network=host --cap-add=NET_ADMIN --cap-add=NET_RAW --env TS_STATE_DIR=/var/lib/tailscale/state --env TS_AUTHKEY --env TS_EXTRA_ARGS='--hostname=%s' tailscale/tailscale"
	machineName := name + "-" + vmName
	dockerCommand = fmt.Sprintf(dockerCommand, machineName)

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
		"docker rm -f tailscaled",
		"sudo rm -rf /var/lib/tailscale/",
		"export TS_AUTHKEY=" + fmt.Sprintf("'%s'", tsAuthKey),
		dockerCommand,
	}

	return sh.RunV(cmd[0], cmd[1:]...)
}

// TailscaleLogs get the logs for the tailscale container
func TailscaleLogs() error {
	name := os.Getenv("RESOURCE_GROUP")
	if name == "" {
		name = fmt.Sprintf("%s-postgres", time.Now().Format("060100"))
	}
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
		"docker logs tailscaled",
	}

	result, err := sh.Output(cmd[0], cmd[1:]...)
	if err != nil {
		return err
	}

	tmp := struct {
		Value []struct {
			Code          string
			DisplayStatus string
			Level         string
			Message       string
		}
	}{}

	err = json.Unmarshal([]byte(result), &tmp)
	if err != nil {
		return err
	}

	fmt.Printf("%s\n", tmp.Value[0].Message)

	return nil
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

// DeployVM deploys vm.bicep to the Azure resource group with parameters
func DeployVM() error {
	name := os.Getenv("RESOURCE_GROUP")
	if name == "" {
		name = fmt.Sprintf("%s-postgres", time.Now().Format("060100"))
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
		"osDiskSize=128",
		"sshKey=" + sshPublicKey,
		"allowIpPort22=" + ipAllow,
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

// Password prints a securely generated password to the standard output
func Password() error {
	password, err := password.Generate(32, 10, 10, false, false)
	if err != nil {
		return err
	}
	fmt.Print(password)
	return nil
}

// DeployPostgres deploys postgres.bicep to the Azure resource group
func DeployPostgres() error {
	// todo: remove PGPASSWORD
	password, err := password.Generate(32, 10, 10, false, false)
	if err != nil {
		return err
	}
	// not required if we write to env.sh
	//fmt.Printf("Password: %s\n", password)

	name := os.Getenv("RESOURCE_GROUP")
	if name == "" {
		name = fmt.Sprintf("%s-postgres", time.Now().Format("060100"))
	}

	ipAllow := os.Getenv("IP_ALLOW")
	if ipAllow == "" {
		res, err := whoAmI()
		if err != nil {
			return err
		}
		ipAllow = res
	}

	file1 := "postgres.bicep"
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
		"size=small",
		"firewallRuleIp=" + ipAllow,
	}
	err = sh.RunV(cmd[0], cmd[1:]...)
	if err != nil {
		return err
	}

	cmd = []string{
		"az",
		"deployment",
		"group",
		"show",
		"--name",
		"postgres",
		"--resource-group",
		name,
		"--out",
		"tsv",
		"--query",
		"properties.outputs.postgresName.value",
	}
	pgName, err := sh.Output(cmd[0], cmd[1:]...)
	if err != nil {
		return err
	}

	// write environment variables to env.sh
	lines := []string{
		"export PGHOST=" + fmt.Sprintf("'%s.postgres.database.azure.com'", pgName),
		"export PGPASSWORD=" + fmt.Sprintf("'%s'", password),
		"export PGPORT='5432'",
		"export PGDATABASE='postgres'",
		"export PGUSER='username'",
	}
	f, err := os.Create("env.sh")
	if err != nil {
		return err
	}
	defer f.Close()
	f.WriteString(strings.Join(lines, "\n"))
	fmt.Printf("environment variables written to env.sh\n")

	return nil
}

// ConfigurePostgres configures ad-admin user and firewall rule
func ConfigurePostgres() error {
	name := os.Getenv("RESOURCE_GROUP")
	if name == "" {
		name = fmt.Sprintf("%s-postgres", time.Now().Format("060100"))
	}
	vmName := os.Getenv("VM_NAME")
	if vmName == "" {
		vmName = "vm1"
	}

	fmt.Printf("getting public ip address\n")
	publicIp, err := sh.Output(
		"az",
		"vm",
		"show",
		"-d",
		"--name",
		vmName,
		"--resource-group",
		name,
		"--out",
		"tsv",
		"--query",
		"publicIps",
	)
	if err != nil {
		return err
	}
	if publicIp == "" {
		return errors.New("publicIps is empty")
	}

	fmt.Printf("getting postgres server name\n")
	postgresName, err := sh.Output(
		"az",
		"postgres",
		"flexible-server",
		"list",
		"--resource-group",
		name,
		"--out",
		"tsv",
		"--query",
		"[0].name",
	)
	if publicIp == "" {
		return fmt.Errorf("No postgres server found in RESOURCE_GROUP %s", name)
	}
	if err != nil {
		return err
	}

	fmt.Printf("getting identity id\n")
	identityId, err := sh.Output(
		"az",
		"identity",
		"show",
		"--resource-group",
		name,
		"--name",
		name+"-identity",
		"--out",
		"tsv",
		"--query",
		"principalId",
	)

	fmt.Printf("creating ad-admin user\n")
	err = sh.RunV(
		"az",
		"postgres",
		"flexible-server",
		"ad-admin",
		"create",
		"--resource-group",
		name,
		"--server-name",
		postgresName,
		"--type",
		"ServicePrincipal",
		"--display-name",
		name+"-identity",
		"--object-id",
		identityId,
	)
	if err != nil {
		return err
	}

	fmt.Printf("updating firewall rule\n")
	err = sh.RunV(
		"az",
		"postgres",
		"flexible-server",
		"firewall-rule",
		"update",
		"--resource-group",
		name,
		"--name",
		postgresName,
		"--rule-name",
		"DefaultAllowRule",
		"--start-ip-address",
		publicIp,
		"--end-ip-address",
		publicIp,
	)
	if err != nil {
		return err
	}
	return nil
}

// SshCommand outputs the SSH command
func SshCommand() error {
	name := os.Getenv("RESOURCE_GROUP")
	if name == "" {
		name = fmt.Sprintf("%s-postgres", time.Now().Format("060100"))
	}
	return sh.RunV(
		"az",
		"deployment",
		"group",
		"show",
		"--name",
		"vm",
		"--resource-group",
		name,
		"--out",
		"tsv",
		"--query",
		"properties.outputs.sshCommand.value",
	)
}

// AcceptTerms accepts the Flatcar VM image terms
func AcceptTerms() error {
	offer := "flatcar-container-linux-free"
	publisher := "kinvolk"
	sku := "stable-gen2"

	return sh.RunV(
		"az",
		"vm",
		"image",
		"terms",
		"accept",
		"--offer",
		offer,
		"--plan",
		sku,
		"--publisher",
		publisher,
	)
}

// Empty empties the Azure resource group
func Empty() error {
	name := os.Getenv("RESOURCE_GROUP")
	if name == "" {
		name = fmt.Sprintf("%s-postgres", time.Now().Format("060100"))
	}
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

// GroupDelete deletes the Azure resource group
func GroupDelete() error {
	name := os.Getenv("RESOURCE_GROUP")
	if name == "" {
		name = fmt.Sprintf("%s-postgres", time.Now().Format("060100"))
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

// EnsureButane downloads butane from GitHub (coreos/butane/releases)
func EnsureButane() error {
	if os.Getenv("SUDO_USER") == "" {
		return errors.New("run this command with sudo")
	}
	switch {
	case runtime.GOOS == "darwin" && runtime.GOARCH == "arm64":
		url1 := "https://github.com/coreos/butane/releases/download/v0.17.0/butane-aarch64-apple-darwin"
		res, err := http.Get(url1)
		if err != nil {
			return err
		}
		defer res.Body.Close()
		file1 := "/usr/local/bin/butane"
		f, err := os.OpenFile(file1, os.O_CREATE|os.O_RDWR|os.O_TRUNC, 0755)
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

// Butane uses the Butane CLI tool to generate ignition.json from cl.yaml
func Butane() error {
	b, err := sh.Output(
		"butane",
		"cl.yaml",
	)
	if err != nil {
		return err
	}
	map1 := map[string]interface{}{}
	err = json.Unmarshal([]byte(b), &map1)
	if err != nil {
		return err
	}
	b1, err := json.MarshalIndent(map1, "", "  ")
	if err != nil {
		return err
	}
	file1 := "ignition.json"
	f1, err := os.Create(file1)
	if err != nil {
		return nil
	}
	defer f1.Close()
	fmt.Fprintf(f1, "%s", b1)
	fmt.Printf("%s\n", b1)
	return nil
}

// Bicep injects ignition.json into the customDataIgnition variable in vm.bicep
func Bicep() error {
	file1 := "vm.bicep"
	b1, err := os.ReadFile(file1)
	if err != nil {
		return err
	}

	file2 := "ignition.json"
	b2, err := os.ReadFile(file2)
	if err != nil {
		return err
	}

	re1 := regexp.MustCompile("var customDataIgnition = '''(.|\n)*'''")

	tmp := []byte(fmt.Sprintf("var customDataIgnition = '''\n%s\n'''", b2))
	b1 = re1.ReplaceAllLiteral(b1, tmp)

	f2, err := os.Create(file1)
	if err != nil {
		return nil
	}
	defer f2.Close()
	fmt.Fprintf(f2, "%s", b1)
	fmt.Printf("%s\n", b1)

	return nil
}

// Env prints the sample environment variables
func Env() {
	tmp1 := `export PGHOST=''
export PGPASSWORD=''
export PGPORT='5432'
export PGDATABASE='postgres'
export PGUSER='username'`
	fmt.Printf("%s\n", tmp1)

}

// PsqlCommand outputs the psql command
func PsqlCommand() error {
	name := os.Getenv("RESOURCE_GROUP")
	if name == "" {
		name = fmt.Sprintf("%s-postgres", time.Now().Format("060100"))
	}
	return sh.RunV(
		"az",
		"deployment",
		"group",
		"show",
		"--name",
		"postgres",
		"--resource-group",
		name,
		"--out",
		"tsv",
		"--query",
		"properties.outputs.postgresUrl.value",
	)
}

// PsqlDocker connect via pql using docker and the latest postgres image
func PsqlDocker() error {
	// https://www.postgresql.org/docs/current/libpq-envars.html
	// connect via:
	// docker run -it -e PGHOST -e PGPASSWORD -e PGPORT -e PGDATABASE -e PGUSER --rm postgres psql "sslmode=require"

	vars := []string{
		"PGHOST",
		"PGPASSWORD",
		"PGPORT",
		"PGDATABASE",
		"PGUSER",
	}
	for _, v := range vars {
		if os.Getenv(v) == "" {
			return fmt.Errorf("%s not set. This command requires: %s", v, strings.Join(vars, ", "))
		}
	}

	return sh.RunV(
		"docker",
		"run",
		"-it",
		"-e",
		"PGHOST",
		"-e",
		"PGPASSWORD",
		"-e",
		"PGPORT",
		"-e",
		"PGDATABASE",
		"-e",
		"PGUSER",
		"--rm",
		"postgres",
		"psql",
		"sslmode=require",
	)
}

// Clean removes files created during deployment
func Clean() error {
	files := []string{
		"env.sh",
		"ignition.json",
	}
	for _, x := range files {
		err := os.RemoveAll(x)
		if err != nil {
			return err
		}
	}
	return nil
}
