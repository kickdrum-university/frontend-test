import "./Header.scss";

function Header() {
  return (
    <header className="header">
      <div className="heading">Item Lister</div>
      <input
        type="search"
        placeholder="Search items..."
        className="search-box"
      ></input>
    </header>
  );
}

export default Header;
