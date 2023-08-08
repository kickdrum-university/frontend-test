import "./Form.scss";

function Form() {
  return (
    <div>
      <form className="form">
        <div className="heading">Add Items</div>
        <input type="text" className="input-field"></input>
        <button type="submit" className="submit-btn">
          Submit
        </button>
      </form>
    </div>
  );
}

export default Form;
