import React, { useState, useRef } from "react";
import { useNavigate } from "react-router-dom";
import "./ChallengePage.css";

function ChallengePage() {
  const apiGatewayId = process.env.REACT_APP_API_GATEWAY_ID;

  const navigate = useNavigate();
  const [output, setOutput] = useState("");
  const intervalRef = useRef(null);

  const simulateStreaming = (text) => {
    let index = 0;
    setOutput("");

    if (intervalRef.current) {
      clearInterval(intervalRef.current);
    }

    intervalRef.current = setInterval(() => {
      if (index < text.length) {
        setOutput((prev) => text.slice(0, index + 1));
        index++;
      } else {
        clearInterval(intervalRef.current);
        intervalRef.current = null;
      }
    }, 10);
  };

  const callEndpoint = async (button) => {
    try {
      const response = await fetch(
        "https://" +
          apiGatewayId +
          ".execute-api.localhost.localstack.cloud:4566/prod" +
          button
      );

      if (!response.ok) {
        throw new Error("Failed to fetch the endpoint");
      }

      const reader = response.body.getReader();
      const decoder = new TextDecoder("utf-8");
      let result = "";

      while (true) {
        const { done, value } = await reader.read();
        if (done) break;

        const chunk = decoder.decode(value, { stream: true });
        result += chunk; // Accumulate the complete response
      }

      // Eliminate all spaces from the result before streaming
      const cleanedResult = result
        .split("\n") // Split the text into lines
        .map((line) => line.replace(/\s{2,}/g, " ").trim()) // Remove extra spaces in each line
        .join("\n");

      // Stream the accumulated text
      simulateStreaming(cleanedResult.trim());
    } catch (error) {
      simulateStreaming("Error connecting to the endpoint");
    }
  };

  return (
    <div className="challenge-page">
      <div className="container">
        <div className="buttons-container">
          <button
            className="button"
            onClick={() => callEndpoint("/suspects/gingerbread")}
          >
            curl /suspects/gingerbread
          </button>
          <button
            className="button"
            onClick={() => callEndpoint("/suspects/elf")}
          >
            curl /suspects/elf
          </button>
          <button
            className="button"
            onClick={() => callEndpoint("/suspects/reindeer")}
          >
            curl /suspects/reindeer
          </button>
          <button
            className="button"
            onClick={() => callEndpoint("/suspects/snowman")}
          >
            curl /suspects/snowman
          </button>
          <button
            className="button"
            onClick={() => callEndpoint("/hints/clue1")}
          >
            curl /hints/clue1
          </button>
          <button
            className="button"
            onClick={() => callEndpoint("/hints/clue2")}
          >
            curl /hints/clue2
          </button>
          <div className="text-area">
            <p>
              Check the real time weather in Las Vegas. If the temperature is
              above 0°C, Frosty the Snowman has melted and can no longer be held
              accountable.
            </p>
          </div>
          <button className="button" onClick={() => callEndpoint("/weather")}>
            curl /weather
          </button>
        </div>

        <div className="text-container">
          <pre className="text-area">{output}</pre>
        </div>

        <div className="navigation-buttons">
          <button
            className="button back-button"
            onClick={() => navigate("/instructions")}
          >
            Back to Instructions
          </button>

          <button
            className="button mystery-button"
            onClick={() => navigate("/mystery")}
          >
            Click to Solve the Mystery
          </button>
        </div>
      </div>
    </div>
  );
}

export default ChallengePage;
