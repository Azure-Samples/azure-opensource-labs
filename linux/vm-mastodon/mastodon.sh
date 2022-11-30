cd $HOME

export SITE_ADDRESS=$(jq -r '.siteAddress' env.json)
export LETS_ENCRYPT_EMAIL=$(jq -r '.letsEncryptEmail' env.json)
export TLS_INTERNAL=''

git clone https://github.com/asw101/tmp -b fractured-monkey-1
cd tmp

make run-postgres
sudo make config
sudo make setup-db
make setup-admin > ../admin.txt
make run
