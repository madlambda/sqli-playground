package main

import (
	"database/sql"
	"fmt"
	"log"
	"net/http"
	"os"

	_ "github.com/go-sql-driver/mysql"
)

var (
	dbuser, dbpass, dbaddr, dbname string
)

func main() {
	fmt.Println("sqli example")

	dbuser = getenv("DBUSER")
	dbpass = getenv("DBPASS")
	dbaddr = getenv("DBADDR")
	dbname = getenv("DBNAME")

	checkdb()

	http.HandleFunc("/news", newsHandler)
	http.HandleFunc("/headers", headersHandler)

	err := http.ListenAndServe(":8080", nil)
	abortif(err != nil, "failed to start http server: %v", err)
}

type newsDetail struct {
	title string
	body  string
}

func newsHandler(w http.ResponseWriter, r *http.Request) {
	db, err := sql.Open("mysql", dbconn())
	if err != nil {
		httpError(w, "failed to connect to database")
		return
	}

	defer db.Close()

	var news []newsDetail

	var query = "SELECT title,body from news"

	filters, ok := r.URL.Query()["filter"]
	if ok && len(filters) > 0 && len(filters[0]) > 1 {
		query += " WHERE title LIKE '%" + filters[0] + "%'"
	}

	rows, err := db.Query(query)
	if err != nil {
		httpError(w, "failed to execute query: %s (error: %v)", query, err)
		return
	}

	for rows.Next() {
		var entry newsDetail
		err = rows.Scan(&entry.title, &entry.body)
		if err == sql.ErrNoRows {
			break
		}

		if err != nil {
			// We return the error message in the HTTP response to easily
			// exploit it. Later we can have an option to hide them, so we can
			// also teach how to blindly recognize the errors.
			httpError(w, "failed to scan resultset: %s (error: %v)", query, err)
			return
		}

		news = append(news, entry)
	}

	renderNews(w, news)
}

func renderNews(w http.ResponseWriter, news []newsDetail) {
	w.WriteHeader(http.StatusOK)
	w.Header().Add("Content-Type", "text/plain; charset=utf-8")

	writeBanner(w)
	for _, entry := range news {
		writeNews(w, entry.title, entry.body)
	}
	writeFooter(w)
}

func writeNews(w http.ResponseWriter, title, body string) {
	fmt.Fprintf(w, "-> %s\n", title)
	fmt.Fprintf(w, "   %s\n\n", body)
}

func writeBanner(w http.ResponseWriter) {
	fmt.Fprintf(w,
		`+------------------------------------------------------------------------------+
| madlambda news network                                                       |
+------------------------------------------------------------------------------+
`)
}

func writeFooter(w http.ResponseWriter) {
	fmt.Fprintf(w,
		`+-----------------------------------------------------------------------------+
| Copyright (c) madlambda                                                      |
+------------------------------------------------------------------------------+`)
}

func httpError(w http.ResponseWriter, format string, args ...interface{}) {
	w.WriteHeader(http.StatusInternalServerError)
	fmt.Fprintf(w, format, args...)

	log.Printf("error: "+format, args...)
}

func headersHandler(w http.ResponseWriter, req *http.Request) {
	for name, headers := range req.Header {
		for _, h := range headers {
			fmt.Fprintf(w, "%v: %v\n", name, h)
		}
	}
}

func getenv(name string) string {
	val := os.Getenv(name)
	abortif(val == "", "env %s does not exists or is empty", name)
	if val == "" {
		os.Exit(1)
	}
	return val
}

func abortif(cond bool, format string, args ...interface{}) {
	if cond {
		abort(format, args...)
	}
}

func abort(format string, args ...interface{}) {
	fmt.Fprintf(os.Stderr, format+"\n", args...)
	os.Exit(1)
}

func dbconn() string {
	return sprintf("%s:%s@tcp(%s)/%s?charset=utf8", dbuser, dbpass, dbaddr, dbname)
}

func checkdb() {
	db, err := sql.Open("mysql", dbconn())
	abortif(err != nil, "failed to open db connection: %v", err)

	defer db.Close()
}

var sprintf = fmt.Sprintf
