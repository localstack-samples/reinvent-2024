import React from "react";
import { useNavigate } from "react-router-dom";
import "./LandingPage.css";

function LandingPage() {
  const navigate = useNavigate();

  return (
    <div className="landing-page">
      <div className="container">
        <div className="content-wrapper">
          <h1 className="title">The</h1>
          <img src="assets/logo.svg" alt="Logo" className="logo" />
          <h1 className="title">Holiday Heist: Win Back the Prizes!</h1>

          <div className="explanation">
            <p>
              It’s two weeks before Festivus, and the North Stack is in chaos.
              Gifts have been stolen. But not just any gifts—oh no, these are
              the top-shelf prizes, the kind that YOU could win if you solve
              this caper. So yeah, no pressure or anything, but the fate of the
              Holidays is basically in your hands. No big deal.
            </p>
          </div>

          <div class="prizes-container">
            <div class="prize">
              <h2>2nd Prize</h2>
              <img src="assets/prize-2.png" alt="Garmin SmartWatch" />
            </div>
            <div class="prize">
              <h2>1st Prize</h2>
              <img src="assets/prize-1.png" alt="Apple AirPods Max" />
            </div>
            <div class="prize">
              <h2>3rd Prize</h2>
              <img
                src="assets/prize-3.png"
                alt="Raspberry Pi 5 + Keychron Keyboard"
              />
            </div>
          </div>

          <button
            className="button proceed-button"
            onClick={() => navigate("/instructions")}
          >
            Proceed to Instructions
          </button>
        </div>
      </div>
    </div>
  );
}

export default LandingPage;
