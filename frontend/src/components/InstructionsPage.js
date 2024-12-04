import React from "react";
import { useNavigate } from "react-router-dom";
import "./InstructionsPage.css";

function LandingPage() {
  const navigate = useNavigate();

  return (
    <div className="landing-page">
      <div className="container">
        <div className="content-wrapper">
          <img src="assets/logo.svg" alt="Logo" className="logo" />

          <div className="explanation">
            <p>
              Thankfully, the AI assistant, FrostByte, acted quickly. Before the
              perpetrator could fully sabotage the system, FrostByte collected
              information about the last active users of the cloud system. Using
              its AWS training, FrostByte stored the data locally using
              LocalStack. But there’s a problem: nobody knows how to access this
              data—except for you.
            </p>
            <p>
              <u>
                <b>Your mission</b>
              </u>
              : As a local cloud expert, you must use LocalStack to figure out
              who the suspects are, uncover the clues, and solve the case. Take
              a very close look at the diagram below to understand the
              architecture of the system running on LocalStack. This is all on
              your machine now. The mistery service will give you all the
              information. The clues are all there, but it’s up to you to piece
              them together. Good luck and don't disappoint everybody!
            </p>
          </div>
          <img src="assets/diagram.svg" alt="Diagram" className="diagram" />
        </div>
        <button className="button back-button" onClick={() => navigate("/")}>
          Back to Landing Page
        </button>

        <button
          className="button mystery-button"
          onClick={() => navigate("/challenge")}
        >
          Proceed to the Challenge
        </button>
      </div>
    </div>
  );
}

export default LandingPage;
