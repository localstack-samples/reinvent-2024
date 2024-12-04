package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
)

func snowmanHandler(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	fmt.Fprintln(w, ` name: Frosty,
	alibi: I was guarding the Ice Gate! Probably. Maybe.,
	suspiciousBehavior: Their scarf was tied to the vault’s handle, but Frosty can’t remember how it got there.,
	clue: Frosty’s a snowperson, not a master thief. They got distracted by a snowball fight. `)
}

func reindeerHandler(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	fmt.Fprintln(w, ` name: Blitzen,
  	alibi: I was practicing sleigh drills and eating candy.,
  	suspiciousBehavior: Candy wrappers were found near the vault, but Blitzen can’t even lift a gift box. Hooves are tricky.,
  	clue: Blitzen insists they ‘only ate the candy,’ and no one disagrees.`)
}

func gingerHandler(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	w.Header().Set("Access-Control-Allow-Origin", "https://frontend.s3-website.localhost.localstack.cloud:4566")
	w.Header().Set("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
	w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")

	fmt.Fprintln(w, ` name: Ginger Snap,
  	alibi: I was testing new cookie designs in the bakery. Got a lot of crumbs to prove it.,
  	suspiciousBehavior: Left cookie crumbs near the vault but has no clue how to open it.,
  	clue: Literally no one believes Ginger Snap could pull this off. `)
}

func elfHandler(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	fmt.Fprintln(w, ` name: Jingles,
  	alibi: I was making the gifts look ‘extra festive.’,
  	suspiciousBehavior: Was seen dragging the ENTIRE gift pile into their workshop, leaving a trail of glitter.,
  	clue: The glitter trail outside the vault matches the glitter now *everywhere* in Jingles’ workshop. Also, there’s a note admitting it. `)
}

func hint1Handler(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	fmt.Fprintln(w,
		` hint: A glitter trail starts at the vault and leads directly into Jingles’ workshop. `)
}

func hint2Handler(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	fmt.Fprintln(w,
		` hint: A giant glittery note left in the vault reads: ‘I’ll put them back! Love, Jingles. `)
}

func answerHandler(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	fmt.Fprintln(w, `It was Jingles all along!`)
}

func weatherHandler(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	url := "https://api.openweathermap.org/data/2.5/weather?lat=36.1716&lon=-115.1391&units=metric&appid=538d99e13d3cf6810899e1e734cba6a6"

	// Make the HTTP GET request
	resp, err := http.Get(url)
	if err != nil {
		log.Fatalf("Error making request: %v", err)
	}
	defer resp.Body.Close()

	// Check for HTTP errors
	if resp.StatusCode != http.StatusOK {
		log.Fatalf("HTTP request failed with status: %s", resp.Status)
	}

	// Read the response body
	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		log.Fatalf("Error reading response: %v", err)
	}

	// Structs for the relevant fields
	type Coordinates struct {
		Lat float64 `json:"lat"`
		Lon float64 `json:"lon"`
	}

	type Weather struct {
		Description string  `json:"description"`
		Temperature float64 `json:"temp"`
		FeelsLike   float64 `json:"feels_like"`
		Humidity    int     `json:"humidity"`
	}

	type Sys struct {
		Country string `json:"country"`
		Sunrise int64  `json:"sunrise"`
		Sunset  int64  `json:"sunset"`
	}

	type ApiResponse struct {
		Name     string      `json:"name"`
		Coord    Coordinates `json:"coord"`
		Weather  []Weather   `json:"weather"`
		Main     Weather     `json:"main"`
		Sys      Sys         `json:"sys"`
		Timezone int         `json:"timezone"`
	}

	// Parse API response
	var data ApiResponse
	err = json.Unmarshal([]byte(body), &data)
	if err != nil {
		log.Fatalf("Error parsing JSON: %v", err)
	}

	// Create simplified JSON
	simplified := map[string]interface{}{
		"location": map[string]interface{}{
			"name": data.Name,
			"coordinates": map[string]float64{
				"latitude":  data.Coord.Lat,
				"longitude": data.Coord.Lon,
			},
			"country": data.Sys.Country,
		},
		"weather": map[string]interface{}{
			"temperature": data.Main.Temperature,
			"feels_like":  data.Main.FeelsLike,
			"humidity":    data.Main.Humidity,
			"description": data.Weather[0].Description,
		},
		"time": map[string]interface{}{
			"timezone_offset": data.Timezone,
			"sunrise":         data.Sys.Sunrise,
			"sunset":          data.Sys.Sunset,
		},
	}

	// Convert to JSON and print
	simplifiedJSON, err := json.MarshalIndent(simplified, "", "  ")
	if err != nil {
		log.Fatalf("Error generating JSON: %v", err)
	}

	fmt.Fprintln(w, string(simplifiedJSON))

}

func main() {

	http.HandleFunc("/suspects/gingerbread", gingerHandler)

	http.HandleFunc("/suspects/reindeer", reindeerHandler)

	http.HandleFunc("/suspects/snowman", snowmanHandler)

	http.HandleFunc("/suspects/elf", elfHandler)

	http.HandleFunc("/hints/clue1", hint1Handler)

	http.HandleFunc("/hints/clue2", hint2Handler)

	http.HandleFunc("/weather", weatherHandler)

	http.HandleFunc("/answer", answerHandler)

	fmt.Println("Starting server on port 8080...")
	if err := http.ListenAndServe(":8080", nil); err != nil {
		fmt.Printf("Server failed: %s\n", err)
	}

}
