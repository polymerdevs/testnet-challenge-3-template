const TestFixture = artifacts.require("TestFixture");

module.exports = function (deployer) {
  deployer.deploy(TestFixture);
};
