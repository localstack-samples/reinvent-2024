package main

import (
	"fmt"
	"net/http"
)

// alibiHandler handles requests to /alibi
func alibiHandler(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	fmt.Fprintln(w, "Alibi endpoint")
}

// guardHandler handles requests to /guard
func guardHandler(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	fmt.Fprintln(w, "Guard endpoint")
}

// locationHandler handles requests to /agent
func locationHandler(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	fmt.Fprintln(w, "Guard endpoint")
}

// employeeHandler handles requests to /employee
func employeeHandler(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	fmt.Fprintln(w, "Employee endpoint")
}

// hint1Handler handles requests to /hint1
func hint1Handler(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	fmt.Fprintln(w, "Hint1 endpoint")
}

// hint2Handler handles requests to /hint2
func hint2Handler(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	fmt.Fprintln(w, "Hint2 endpoint")
}

func main() {

	http.HandleFunc("/location", locationHandler)

	http.HandleFunc("/guard", guardHandler)

	http.HandleFunc("/alibi", alibiHandler)

	http.HandleFunc("/employee", employeeHandler)

	http.HandleFunc("/hint1", hint1Handler)

	http.HandleFunc("/hint2", hint2Handler)

	fmt.Println("Starting server on port 8080...")
	if err := http.ListenAndServe(":8080", nil); err != nil {
		fmt.Printf("Server failed: %s\n", err)
	}
}
