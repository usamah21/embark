say "$(cat << 'MSG'

If node < 8.11.3 attempts to directly install embark then npm will report error
and exit. This does not apply to older versions of node/npm installing embark
as a dependency, e.g. per some DApp's package.json

MSG
)"

cd ~/working/embark
nac pre-lts-newer-npm

bash -i << 'DEMO'
npm install .
DEMO

nac default
cd ~
