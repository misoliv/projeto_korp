package main

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"
)

func TestProjetoKorpEndpoint(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/projeto-korp", nil)
	rec := httptest.NewRecorder()

	projetoKorpHandler(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("esperado status 200, recebido %d", rec.Code)
	}

	var response ProjetoKorpResponse

	if err := json.Unmarshal(rec.Body.Bytes(), &response); err != nil {
		t.Fatalf("erro ao interpretar JSON: %v", err)
	}

	if response.Nome != "Projeto Korp" {
		t.Errorf("esperado nome Projeto Korp, recebido %s", response.Nome)
	}

	horario, err := time.Parse(time.RFC3339, response.Horario)
	if err != nil {
		t.Fatalf("horário inválido: %v", err)
	}

	if horario.Location() != time.UTC {
		t.Errorf("esperado horário UTC")
	}
}

func TestHealthEndpoint(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/health", nil)
	rec := httptest.NewRecorder()

	healthHandler(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("esperado status 200, recebido %d", rec.Code)
	}

	var response HealthResponse

	if err := json.Unmarshal(rec.Body.Bytes(), &response); err != nil {
		t.Fatalf("erro ao interpretar JSON: %v", err)
	}

	if response.Status != "ok" {
		t.Errorf("esperado status ok, recebido %s", response.Status)
	}
}

func TestProjetoKorpRejectsPost(t *testing.T) {
	req := httptest.NewRequest(http.MethodPost, "/projeto-korp", nil)
	rec := httptest.NewRecorder()

	projetoKorpHandler(rec, req)

	if rec.Code != http.StatusMethodNotAllowed {
		t.Fatalf(
			"esperado status 405, recebido %d",
			rec.Code,
		)
	}
}
