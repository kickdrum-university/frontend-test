import React from "react";
import logo from "./logo.svg";
import "./App.css";
import Header from "./components/header/Header";
import ItemContainer from "./components/item-container/ItemContainer";

function App() {
  return (
    <div className="App">
      <Header />
      <ItemContainer />
    </div>
  );
}

export default App;
