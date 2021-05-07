const CukieSwapV1 = artifacts.require("CukieSwapV1");

async function main() {
    const cukieSwapV1 = await CukieSwapV1.new();
    await CukieSwapV1.setAsDeployed(cukieSwapV1);

    console.log("CukieSwapV1 deployed to:", cukieSwapV1.address);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });