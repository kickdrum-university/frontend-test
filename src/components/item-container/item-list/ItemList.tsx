import "./ItemList.scss";
import Item from "./item/Item";

function ItemList() {
  const items = ["item1", "item2", "item3", "item4"];

  return (
    <div className="itemList">
      <div className="heading">Items</div>
      <Item item={items[0]} />
      <Item item={items[1]} />
      <Item item={items[2]} />
    </div>
  );
}

export default ItemList;
