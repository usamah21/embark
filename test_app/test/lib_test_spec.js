contract("Test", function() {
  before(function(done) {
    this.timeout(0);
    var contractsConfig = {
      "Test2": {
      },
      "Test": {
        "gas": 2000000
      },
      "ZAMyLib": {
      },
      "ZAMyLib2": {
        "deploy": true
      },
      "SimpleStorage": {
        args: [100]
      },
      "AnotherStorage": {
        args: ["$SimpleStorage"]
      },
      "Token": {
        deploy: false,
        args: [1000]
      },
      "MyToken": {
        instanceOf: "Token"
      },
      "MyToken2": {
        instanceOf: "Token",
        args: [2000]
      },
      "ContractArgs": {
        "args": {
          "initialValue": 123,
          "_addresses": ["$MyToken2", "$SimpleStorage"]
        }
      },
      "SomeContract": {
        "args": [
          ["$MyToken2", "$SimpleStorage"],
          100
        ]
      }
    };


    EmbarkSpec.deployAll(contractsConfig, () => { done() });
  });

  it("should call library correctly", function(done) {
    Test2.methods.testAdd().call().then(function(result) {
      assert.equal(result, 3);
      done();
    });
  });

});