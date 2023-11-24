const hre = require("hardhat")

async function main() {
    // Chain dependent variables
    const networkName = hre.network.name
    let desiredGasPrice, ownerAddress, initialSupply, governorAddress, tokens, priceFeeds, initialListings = []

    if (networkName == "goerli") {
        desiredGasPrice = 1
        ownerAddress = "0x45faf7923BAb5A5380515E055CA700519B3e4705"
        initialSupply = 250
        governorAddress = "0x45faf7923BAb5A5380515E055CA700519B3e4705"
        tokens = [
            "0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6" // WETH
        ]
        priceFeeds = [
            "0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e" // WETH
        ]
    } else if (networkName == "bsc") {
        desiredGasPrice = 3
        ownerAddress = ""
        initialSupply = 0
        governorAddress = ""
        tokens = [
            "" // WBNB
        ]
        priceFeeds = [
            "" // WBNB
        ]
    }


    // Checking gas price
    await checkGasPrice(desiredGasPrice)
    console.log("Chain:", networkName)


    // Contracts
    // Deploying CFI
    const cfiContract = await hre.ethers.deployContract("CFI", [ownerAddress, initialSupply])
    await cfiContract.waitForDeployment()
    const cfiDeployTxHash = await cfiContract.deploymentTransaction().hash
    const cfiDeployTx = await hre.ethers.provider.getTransactionReceipt(cfiDeployTxHash)
    console.log("CFI deployed to:", cfiContract.target)
    console.log("at block number:", cfiDeployTx.blockNumber)

    // Deploying CFIPublic
    const cfiPublicContract = await hre.ethers.deployContract("CFIPublic", [governorAddress])
    await cfiPublicContract.waitForDeployment()
    const cfiPublicDeployTxHash = await cfiPublicContract.deploymentTransaction().hash
    const cfiPublicDeployTx = await hre.ethers.provider.getTransactionReceipt(cfiPublicDeployTxHash)
    console.log("CFIPublic deployed to:", cfiPublicContract.target)
    console.log("at block number:", cfiPublicDeployTx.blockNumber)


    // Addresses
    const cfiAddress = cfiContract.target
    const cfiPublicAddress = cfiPublicContract.target
    // const cfiAddress = ""
    // const cfiPublicAddress = ""


    // Initial listings
    initialListings.push(cfiAddress)
    initialListings.push(cfiPublicAddress)


    // Deploying Marketplace
    const marketplaceContract = await hre.ethers.deployContract(
        "Marketplace",
        [governorAddress, tokens, priceFeeds, initialListings]
    )
    await marketplaceContract.waitForDeployment()
    const marketplaceDeployTxHash = await marketplaceContract.deploymentTransaction().hash
    const marketplaceDeployTx = await hre.ethers.provider.getTransactionReceipt(marketplaceDeployTxHash)
    console.log("Marketplace deployed to:", marketplaceContract.target)
    console.log("at block number:", marketplaceDeployTx.blockNumber)


    // Addresses
    const marketplaceAddress = marketplaceContract.target
    // const marketplaceAddress = ""


    // Verifying contracts
    await new Promise(resolve => setTimeout(resolve, 20000))
    await verify(cfiAddress, [ownerAddress, initialSupply])
    await verify(cfiPublicAddress, [governorAddress])
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

async function verify(address, constructorArguments) {
    console.log(`verify ${address} with arguments ${constructorArguments.join(",")}`)
    try {
        await hre.run("verify:verify", {
            address,
            constructorArguments
        })
    } catch(error) { console.log(error) }
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
    process.exit()
})
