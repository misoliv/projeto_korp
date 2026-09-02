# ---------- Etapa de build ----------
FROM golang:1.27-alpine AS builder

WORKDIR /app

COPY go.mod ./

COPY . .

RUN go test ./...

RUN CGO_ENABLED=0 GOOS=linux go build \
    -trimpath \
    -ldflags="-s -w" \
    -o /http-server-projeto-korp .


# ---------- Etapa de execução ----------
FROM scratch

COPY --from=builder \
    /http-server-projeto-korp \
    /http-server-projeto-korp

USER 65532:65532

EXPOSE 8080

ENTRYPOINT ["/http-server-projeto-korp"]