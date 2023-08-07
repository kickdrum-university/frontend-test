import React from "react";
import logo from "./logo.svg";
import "./App.css";

function App() {
  const password = "123456prei";
  return (
    <div className="App">
      <header className="App-header">
        <img src={logo} className="App-logo" alt="logo" />
        <p>
          Edit <code>src/App.tsx</code> and save to oooreload.
        </p>
        <a
          className="App-link"
          href="https://reactjs.org"
          target="_blank"
          rel="noopener noreferrer"
        >
          Learn React
        </a>
        <p>
          Frontend testing prcommt re-ph stpush sonarQue added it Exercise-1
          {password}
        </p>
      </header>
    </div>
  );
}

export default App;
