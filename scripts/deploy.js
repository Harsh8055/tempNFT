
const hre = require("hardhat");

async function main() {

  const TempNFT = await hre.ethers.getContractFactory("TempNFT");
  const tempnft = await Greeter.deploy();

  await tempnft.deployed();

  console.log("tempnft deployed to:", tempnft.address);
  
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
