const OpenAuction = artifacts.require("OpenAuction");

module.exports = function (deployer) {
  deployer.deploy(OpenAuction,50000,"0xD2D8291f4ebE77337107B332dD4B0ccea0152f41");
};
