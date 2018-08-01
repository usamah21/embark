/*global EmbarkJS, Web3, __MessageEvents */

// for the whisper v5 and web3.js 1.0
let __embarkWhisperNewWeb3 = {};

__embarkWhisperNewWeb3.setProvider = function (options) {
  let provider;
  if (options === undefined) {
    provider = "localhost:8546";
  } else {
    provider = options.server + ':' + options.port;
  }

  if(options.type === 'rpc'){
    this.web3 = new Web3(new Web3.providers.HttpProvider("http://" + provider));
  }
  else {
    this.web3 = new Web3(new Web3.providers.WebsocketProvider("ws://" + provider));
  }
  this.isAvailable().then((isAvailable) => {
    if (!isAvailable) {
      return console.log("whisper not available");
    } 
    
    this.getWhisperVersion((err, version) => {
      
      if (this._isMethodNotFoundErr(err) || version >= 5) {
        this.web3.shh.newSymKey().then((id) => {
          this.symKeyID = id;
        });
        this.web3.shh.newKeyPair().then((id) => {
          this.sig = id;
        });
      } else {
        throw new Error("version of whisper not supported");
      }
      if (err) {
        this.whisperVersion = 'unknown';
      } 
      else { this.whisperVersion = this.web3.version.whisper; }
    });
  });
  
};

__embarkWhisperNewWeb3.sendMessage = function (options) {
  var topics, data, ttl, payload;
  topics = options.topic || options.topics;
  data = options.data || options.payload;
  ttl = options.ttl || 100;
  var powTime = options.powTime || 3;
  var powTarget = options.powTarget || 0.5;

  if (topics === undefined) {
    throw new Error("missing option: topic");
  }

  if (data === undefined) {
    throw new Error("missing option: data");
  }

  topics = this.web3.utils.toHex(topics).slice(0, 10);

  payload = JSON.stringify(data);

  let message = {
    symKeyID: this.symKeyID, // encrypts using the sym key ID
    sig: this.sig, // signs the message using the keyPair ID
    ttl: ttl,
    topic: topics,
    topics: [topics],
    payload: EmbarkJS.Utils.fromAscii(payload),
    powTime: powTime,
    powTarget: powTarget
  };

  this.web3.shh.post(message, function () {
  });
};

__embarkWhisperNewWeb3.listenTo = function (options, callback) {
  var topics = options.topic || options.topics;

  let promise = new __MessageEvents();

  if (typeof topics === 'string') {
    topics = [this.web3.utils.toHex(topics).slice(0, 10)];
  } else {
    topics = topics.map((t) => this.web3.utils.toHex(t).slice(0, 10));
  }

  let filter = this.web3.shh.subscribe("messages", {
    symKeyID: this.symKeyID,
    topics: topics
  }).on('data', function (result) {
    var payload = JSON.parse(EmbarkJS.Utils.toAscii(result.payload));
    var data;
    data = {
      topic: EmbarkJS.Utils.toAscii(result.topic),
      data: payload,
      //from: result.from,
      time: result.timestamp
    };

    if (callback) {
      return callback(null, data);
    }
    promise.cb(payload, data, result);
  });

  promise.filter = filter;

  return promise;
};

__embarkWhisperNewWeb3.getWhisperVersion = function (cb) {
  this.web3.shh.getVersion(function (err, version) {
    cb(err, version);
  });
};

__embarkWhisperNewWeb3.getInfo = function (cb) {
  this.web3.shh.getInfo(function (err, info) {
    cb(err, info);
  });
};

__embarkWhisperNewWeb3.isAvailable = function () {
  return new Promise((resolve, reject) => {
    if (!this.web3.shh) {
      return resolve(false);
    }
    // try {
      this.getWhisperVersion((err) => {
        if(err && this._isMethodNotFoundErr(err)){
          this.getInfo((err, info) => {
            resolve(!err && Boolean(info));
          });
        }
        else resolve(Boolean(!err));
      });
    //}
    // catch (err) {
    //   if(this._isMethodNotFoundErr(err)){
    //     try{
    //       this.getWhisperVersion((err) => {
    //         resolve(Boolean(!err));
    //       });
    //     }
    //     catch(errGetInfo){
    //       reject(errGetInfo);
    //     }
    //   }
    //   reject(err);
    // }
  //});
});
};

__embarkWhisperNewWeb3._isMethodNotFoundErr = function(err){
  if(!err || !err.message) return false;
  
  return err.message.indexOf('Returned error: Method not found') > -1;
};
