import React, { useState } from "react";
import "./MysteryPage.css";
import { useNavigate } from "react-router-dom";

function MysteryPage() {
  const apiGatewayId = process.env.REACT_APP_API_GATEWAY_ID;

  const navigate = useNavigate();

  const [name, setName] = useState(""); // State for "Your Name"
  const [answer, setAnswer] = useState(""); // State for "Your Answer"
  const [result, setResult] = useState(null);

  const handleSubmit = async () => {
    if (!name.trim() || !answer.trim()) {
      setResult("Both name and answer fields are required.");
      return;
    }
    try {
      const response = await fetch(
        "https://" +
          apiGatewayId +
          ".execute-api.localhost.localstack.cloud:4566/prod/lambda",
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "Access-Control-Allow-Headers": "*",
            "Access-Control-Allow-Origin": "*",
          },
          body: JSON.stringify({
            name,
            answer,
          }),
        }
      );

      if (response.status === 200) {
        setResult(
          <>
            Success! You solved the mystery! Go to the{" "}
            <a
              href="https://app.localstack.cloud/inst/default/status"
              target="_blank"
              rel="noopener noreferrer"
            >
              web app
            </a>
            , and find the S3 service. You'll see a bucket called
            'certificate-bucket', which holds your certificate. Download it and
            send it to us as proof that you solved the mystery!
          </>
        );
      } else if (response.status === 204) {
        setResult("Sorry, that's not the correct answer. Try again!");
      } else {
        setResult("An unexpected error occurred.");
      }
    } catch (error) {
      setResult("Error connecting to the server");
    }
  };

  return (
    <div className="mystery-page">
      <div className="container">
        <div className="mystery-content">
          <p className="instructions">
            Enter your name and the name of the perpetrator to solve the
            mystery:
          </p>

          <input
            type="text"
            className="input-field"
            value={name}
            onChange={(e) => setName(e.target.value)} // Update the name state
            placeholder="Enter your name here"
          />

          <input
            type="text"
            className="input-field"
            value={answer}
            onChange={(e) => setAnswer(e.target.value)} // Update the answer state
            placeholder="Enter your answer here"
          />

          <button className="button solve-button" onClick={handleSubmit}>
            Solve Mystery
          </button>

          {result && <div className="result-message">{result}</div>}
        </div>
      </div>
      <div className="navigation-buttons">
        <button
          className="button back-button"
          onClick={() => navigate("/challenge")}
        >
          Go Back to the Clues
        </button>
      </div>
    </div>
  );
}

export default MysteryPage;
