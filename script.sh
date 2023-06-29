git clone git@github.com:rollkit/rollkit.git
cd rollkit
git checkout main
cd ..
git clone git@github.com:rollkit/cosmos-sdk.git
cd cosmos-sdk
latestTag=$(git describe --tags `git rev-list --tags --max-count=1`)
git checkout $latestTag
go mod edit -replace github.com/rollkit/rollkit=../rollkit
go mod tidy
go mod download
cd ..
ignite scaffold chain gm --address-prefix gm
cd gm
go mod edit -replace github.com/cosmos/cosmos-sdk=github.com/rollkit/cosmos-sdk@v0.46.7-rollkit-v0.7.3-no-fraud-proofs
go mod edit -replace github.com/tendermint/tendermint=github.com/celestiaorg/tendermint@v0.34.22-0.20221202214355-3605c597500d
go mod tidy
go mod download

VALIDATOR_NAME=validator1
CHAIN_ID=gm
KEY_NAME=gm-key
KEY_2_NAME=gm-key-2
CHAINFLAG="--chain-id ${CHAIN_ID}"
TOKEN_AMOUNT="10000000000000000000000000stake"
STAKING_AMOUNT="1000000000stake"

# create a random Namespace ID for your rollup to post blocks to
NAMESPACE_ID=$(openssl rand -hex 8)
echo $NAMESPACE_ID

# query the DA Layer start height, in this case we are querying
# our local devnet at port 26657, the RPC. The RPC endpoint is
# to allow users to interact with Celestia's nodes by querying
# the node's state and broadcasting transactions on the Celestia
# network. The default port is 26657.
DA_BLOCK_HEIGHT=$(curl http://0.0.0.0:26650/block | jq -r '.result.block.header.height')
echo $DA_BLOCK_HEIGHT

# build the gm chain with Rollkit
ignite chain build
 reset any existing genesis/chain data
gmd tendermint unsafe-reset-all

# initialize the validator with the chain ID you set
gmd init $VALIDATOR_NAME --chain-id $CHAIN_ID

# add keys for key 1 and key 2 to keyring-backend test
gmd keys add $KEY_NAME --keyring-backend test
gmd keys add $KEY_2_NAME --keyring-backend test

# add these as genesis accounts
gmd add-genesis-account $KEY_NAME $TOKEN_AMOUNT --keyring-backend test
gmd add-genesis-account $KEY_2_NAME $TOKEN_AMOUNT --keyring-backend test

# set the staking amounts in the genesis transaction
gmd gentx $KEY_NAME $STAKING_AMOUNT --chain-id $CHAIN_ID --keyring-backend test

# collect genesis transactions
gmd collect-gentxs

# start the chain
gmd start --rollkit.aggregator true --rollkit.da_layer celestia --rollkit.da_config='{"base_url":"http://localhost:26659","timeout":60000000000,"fee":6000,"gas_limit":6000000}' --rollkit.namespace_id $NAMESPACE_ID --rollkit.da_start_height $DA_BLOCK_HEIGHT

# uncomment the next command if you are using lazy aggregation
# gmd start --rollkit.aggregator true --rollkit.da_layer celestia --rollkit.da_config='{"base_url":"http://localhost:26659","timeout":60000000000,"fee":6000,"gas_limit":6000000}' --rollkit.namespace_id $NAMESPACE_ID --rollkit.da_start_height $DA_BLOCK_HEIGHT --rollkit.lazy_aggregator true
