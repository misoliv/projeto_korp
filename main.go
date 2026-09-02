package main

import (
	"encoding/json"
	"log"
	"net/http"
	"time"
)

type ProjetoKorpResponse struct {
	Nome    string `json:"nome"`
	Horario string `json:"horario"`
}

type HealthResponse struct {
	Status string `json:"status"`
}

func projetoKorpHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	response := ProjetoKorpResponse{
		Nome:    "Projeto Korp",
		Horario: time.Now().UTC().Format(time.RFC3339),
	}

	w.Header().Set("Content-Type", "application/json")

	if err := json.NewEncoder(w).Encode(response); err != nil {
		http.Error(w, "erro interno", http.StatusInternalServerError)
	}
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	response := HealthResponse{
		Status: "ok",
	}

	w.Header().Set("Content-Type", "application/json")

	if err := json.NewEncoder(w).Encode(response); err != nil {
		http.Error(w, "erro interno", http.StatusInternalServerError)
	}
}

func main() {
	http.HandleFunc("/projeto-korp", projetoKorpHandler)
	http.HandleFunc("/health", healthHandler)

	log.Println("Servidor iniciado na porta 8080")

	if err := http.ListenAndServe(":8080", nil); err != nil {
		log.Fatal(err)
	}
}
