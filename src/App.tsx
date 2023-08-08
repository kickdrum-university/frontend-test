import React from "react";
import "./App.css";
import Header from "./components/header/Header";
import ItemContainer from "./components/item-container/ItemContainer";
// import Item from "./components/item-container/item-list/item/Item";

function App() {
  return (
    <div className="App">
      <Header />
      <ItemContainer />
    </div>
  );
}

export default App;
