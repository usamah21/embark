say "$(cat << 'MSG'

If a node < version specified in global embark's "{engines: {...}}" is used to
run embark then report error and exit

MSG
)"

cd ~/embark_demo
nac pre-lts-newer-npm

bash -i << 'DEMO'
node ~/working/embark/bin/embark version
DEMO

nac default
cd ~
