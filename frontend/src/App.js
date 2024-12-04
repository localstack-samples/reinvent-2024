import React from "react";
import { BrowserRouter as Router, Routes, Route } from "react-router-dom";
import Snowfall from "react-snowfall";
import LandingPage from "./components/LandingPage";
import ChallengePage from "./components/ChallengePage";
import MysteryPage from "./components/MysteryPage";
import InstructionsPage from "./components/InstructionsPage";
import "./App.css";

function App() {
  return (
    <Router>
      <div className="app">
        <Snowfall
          color="white"
          snowflakeCount={200}
          style={{
            position: "fixed",
            width: "100vw",
            height: "100vh",
            zIndex: 1,
          }}
        />
        <div className="content">
          <Routes>
            <Route path="/" element={<LandingPage />} />
            <Route path="/challenge" element={<ChallengePage />} />
            <Route path="/mystery" element={<MysteryPage />} />
            <Route path="/instructions" element={<InstructionsPage />} />
          </Routes>
        </div>
      </div>
    </Router>
  );
}

export default App;
