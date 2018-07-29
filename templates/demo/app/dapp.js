import React from 'react';
import ReactDOM from 'react-dom';
import { Tabs, Tab } from 'react-bootstrap';

import EmbarkJS from 'Embark/EmbarkJS';
import Blockchain from './components/blockchain';
import Whisper from './components/whisper';
import Storage from './components/storage';

import './dapp.css';

// use this to access the EmbarkJS API from the browser dev tools
window.EmbarkJS = EmbarkJS;

class App extends React.Component {

  constructor(props) {
    super(props);

    this.state = {
      whisperEnabled: false,
      storageEnabled: false
    }
  }

  _checkMessages = async() => {
    let isAvailable = false;
    if (!EmbarkJS.isNewWeb3() && EmbarkJS.Messages.providerName === 'whisper') {
      isAvailable = await EmbarkJS.Messages.Providers.whisper.isAvailable();
    } else {
      isAvailable = EmbarkJS.Messages.isAvailable();
    }
    this.setState({whisperEnabled: isAvailable})
  }
  
  _checkStorage = async() => {
    const storageEnabled = await EmbarkJS.Storage.isAvailable();
    this.setState({
      storageEnabled: storageEnabled
    });
  }

  componentDidMount(){ 
    EmbarkJS.onReady(() => {
      this._checkMessages();
      this._checkStorage();
    });
  }


  _renderStatus(title, available){
    let className = available ? 'pull-right status-online' : 'pull-right status-offline';
    return <React.Fragment>
      {title} 
      <span className={className}></span>
    </React.Fragment>;
  }

  render(){
    return (<div><h3>Embark - Usage Example</h3>
      <Tabs defaultActiveKey={1} id="uncontrolled-tab-example">
        <Tab eventKey={1} title="Blockchain">
          <Blockchain />
        </Tab>
        <Tab eventKey={2} title={this._renderStatus('Decentralized Storage', this.state.storageEnabled)}>
          <Storage enabled={this.state.storageEnabled} />
        </Tab>
        <Tab eventKey={3} title={this._renderStatus('P2P communication (Whisper/Orbit)', this.state.whisperEnabled)}>
          <Whisper enabled={this.state.whisperEnabled} />
        </Tab>
      </Tabs>
    </div>);
  }
}

ReactDOM.render(<App></App>, document.getElementById('app'));
