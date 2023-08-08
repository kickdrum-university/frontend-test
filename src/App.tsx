import React from "react";
import "./App.css";
import Header from "./components/header/Header";
import ItemContainer from "./components/item-container/ItemContainer";

function App() {
  var abc = "unused variableis";

  return (
    <div className="App">
      <Header />
      <ItemContainer />
    </div>
  );
}

export default App;
