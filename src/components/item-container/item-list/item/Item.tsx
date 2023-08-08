import React from "react";
import "./Item.scss";

interface ItemProps {
  item: string;
}

const Item: React.FC<ItemProps> = (props) => {
  return (
    <div className="item">
      <div className="item-name">{props.item}</div>
      <button type="button" className="remove-btn">
        x
      </button>
    </div>
  );
};

export default Item;
