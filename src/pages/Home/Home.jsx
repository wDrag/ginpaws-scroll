import "./Home.scss";
import { useNavigate } from "react-router-dom";

const Home = () => {
  const navigate = useNavigate();
  return <div style={{ height: "100px", }} onClick={() => navigate("/swap")}>
    <span style={{ cursor: "pointer", backgroundColor: "pink", borderRadius: "15px", padding: "10px", margin: "20px" }}>
      Open App
    </span>
  </div >;
};

export default Home;
