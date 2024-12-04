# React Challenge App

This is a modern React application with a landing page, challenge page, and mystery solving functionality.

## Setup Instructions

1. First, make sure you have Node.js installed on your system (version 14 or higher recommended).

2. Clone this repository and navigate to the project directory:
   ```bash
   cd react-challenge-app
   ```

3. Install the required dependencies:
   ```bash
   npm install
   ```

4. Add your background image:
   - Place your background image in the `public` folder
   - Update the background image path in `src/App.css`

5. Add your logo and diagram:
   - Place your logo image as `logo.png` in the `public` folder
   - Place your diagram image as `diagram.png` in the `public` folder

6. Start the development server:
   ```bash
   npm start
   ```

The application will start and be available at http://localhost:3000

## Features

- Modern Apple-inspired design
- Animated snowfall background
- Responsive layout
- Three main pages:
  1. Landing page with logo, title, explanation, and diagram
  2. Challenge page with interactive buttons and streaming responses
  3. Mystery page with answer submission functionality

## Customization

- To modify the styling, edit the CSS files in the `src/components` directory
- To update the content, modify the respective component files
- To change the endpoint URLs, update them in the ChallengePage.js and MysteryPage.js files

## Notes

- Make sure your LocalStack endpoint is running and accessible at http://localstack.localhost.cloud:4566
- The snowfall animation can be adjusted by modifying the snowflakeCount prop in App.js
- All buttons and interactive elements feature hover animations and modern styling