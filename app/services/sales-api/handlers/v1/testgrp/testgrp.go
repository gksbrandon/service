// Package testgrp contains all the test handlers.
package testgrp

import (
	"context"
	"errors"
	"math/rand"
	"net/http"

	"github.com/gksbrandon/service/business/sys/validate"
	"github.com/gksbrandon/service/foundation/web"
	"go.uber.org/zap"
)

// Handlers manages the set of check endpoints.
type Handlers struct {
	Log *zap.SugaredLogger
}

// Test handler is for development.
func (h Handlers) Test(ctx context.Context, w http.ResponseWriter, r *http.Request) error {
	// Testing errors
	if n := rand.Intn(100); n%2 == 0 {
		// Untrusted error
		// return errors.New("untrusted error")

		// Trusted error
		return validate.NewRequestError(errors.New("trusted error"), http.StatusBadRequest)

		// Shutdown error
		// return web.NewShutdownError("restart service")

		// Panic
		// panic("testing panic")
	}

	status := struct {
		Status string
	}{
		Status: "OK",
	}

	return web.Respond(ctx, w, status, http.StatusOK)
}
