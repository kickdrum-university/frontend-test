import "./ItemContainer.scss";
import Form from "./form/Form";
import ItemList from "./item-list/ItemList";

function ItemContainer() {
  return (
    <div className="item-container">
      <Form />
      <ItemList />
    </div>
  );
}

export default ItemContainer;
