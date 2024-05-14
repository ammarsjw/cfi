const hre = require("hardhat")

async function main() {
    // Chain dependent variables.
    const networkName = hre.network.name
    let desiredGasPrice
    let ownerAddress, initialSupply, cfiBaseURI
    let governorAddress, cfiPublicBaseURI
    let tokens, priceFeeds

    if (networkName == "goerli") {
        desiredGasPrice = 1

        ownerAddress = "0x6F3fDdF3B497caB73C10A314f63a72d8D9F89C1a"
        initialSupply = 250
        cfiBaseURI = "ipfs://bafybeiemxfskgv4ykxkl4y7qvvxvklj564ffmft7ygvngr4o2sa3t3yu4i/"

        governorAddress = "0x6F3fDdF3B497caB73C10A314f63a72d8D9F89C1a"
        cfiPublicBaseURI = "ipfs://bafybeifwp32qb5rs7vauludqwvwyq56mwunbdei3wdrklism2uubzytjs4/"

        tokens = [
            "0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6"    // WETH
        ]
        priceFeeds = [
            "0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e"    // WETH
        ]
    } else if (networkName == "sepolia") {
        desiredGasPrice = 10

        ownerAddress = "0x45faf7923BAb5A5380515E055CA700519B3e4705"
        initialSupply = 500
        cfiBaseURI = "ipfs://bafybeiemxfskgv4ykxkl4y7qvvxvklj564ffmft7ygvngr4o2sa3t3yu4i/"

        governorAddress = "0x45faf7923BAb5A5380515E055CA700519B3e4705"
        cfiPublicBaseURI = "ipfs://bafybeifwp32qb5rs7vauludqwvwyq56mwunbdei3wdrklism2uubzytjs4/"

        tokens = [
            ""    // WETH
        ]
        priceFeeds = [
            ""    // WETH
        ]
    } else if (networkName == "bsc") {
        desiredGasPrice = 3

        ownerAddress = ""
        initialSupply = 0
        cfiBaseURI = "ipfs://aaa/"

        governorAddress = ""
        cfiPublicBaseURI = "ipfs://aaa/"

        tokens = [
            ""    // WBNB
        ]
        priceFeeds = [
            ""    // WBNB
        ]
    }


    // Checking gas price.
    await checkGasPrice(desiredGasPrice)
    console.log("Chain:", networkName)


    // Deploying collections.
    const cfiAddress = await deploy("CFI", [ownerAddress, initialSupply, cfiBaseURI])
    const cfiPublicAddress = await deploy("CFIPublic", [governorAddress, cfiPublicBaseURI])
    // const cfiAddress = ""
    // const cfiPublicAddress = ""


    // Deployment dependent variables.
    let initialListings = []
    initialListings.push(cfiAddress)
    initialListings.push(cfiPublicAddress)


    // Deploying contracts.
    const marketplaceAddress = await deploy("Marketplace", [governorAddress, tokens, priceFeeds, initialListings])
    // const marketplaceAddress = ""


    // Verifying contracts.
    await new Promise(resolve => setTimeout(resolve, 20000))
    await verify(cfiAddress, [ownerAddress, initialSupply, cfiBaseURI])
    await verify(cfiPublicAddress, [governorAddress, cfiPublicBaseURI])
    await verify(marketplaceAddress, [governorAddress, tokens, priceFeeds, initialListings])


    process.exit()
}

async function checkGasPrice(desiredGasPrice) {
    let feeData = await hre.ethers.provider.getFeeData()
    let gasPrice = hre.ethers.formatUnits(feeData.gasPrice, "gwei")
    console.log("Gas Price:", gasPrice, "Gwei")

    while (gasPrice > desiredGasPrice) {
        feeData = await hre.ethers.provider.getFeeData()

        if (gasPrice != hre.ethers.formatUnits(feeData.gasPrice, "gwei")) {
            gasPrice = hre.ethers.formatUnits(feeData.gasPrice, "gwei")
            console.log("Gas Price:", gasPrice, "Gwei")
        }
    }
}

async function deploy(contractToDeploy, constructorArguments) {
    const contract = await hre.ethers.deployContract(contractToDeploy, constructorArguments)
    await contract.waitForDeployment()
    const contractAddress = contract.target
    const deploymentTxHash = await contract.deploymentTransaction().hash
    const deploymentTx = await hre.ethers.provider.getTransactionReceipt(deploymentTxHash)
    const deploymentBlockNumber = deploymentTx.blockNumber
    console.log(`${contractToDeploy} deployed to:`, contractAddress)
    console.log("at block number:", deploymentBlockNumber)
    return contractAddress
}

async function verify(address, constructorArguments) {
    console.log(`verify ${address} with arguments ${constructorArguments.join(",")}`)

    try {
        await hre.run("verify:verify", {address, constructorArguments})
    } catch (error) { console.log(error) }
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
    process.exit()
})
