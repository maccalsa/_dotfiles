#!/bin/bash
LANG="$1"
DB_TYPE=$(zenity --list --title="DB Connection" --column="DB Type" PostgreSQL MySQL SQLite)

case "$LANG" in
  python)
    case "$DB_TYPE" in
      PostgreSQL) snippet="import psycopg2\nconn = psycopg2.connect('dbname=test user=postgres password=secret')";;
      MySQL) snippet="import mysql.connector\nconn = mysql.connector.connect(user='root', password='secret', host='127.0.0.1', database='test')";;
      SQLite) snippet="import sqlite3\nconn = sqlite3.connect('example.db')";;
    esac
    ;;
  java|kotlin)
    case "$DB_TYPE" in
      PostgreSQL) snippet="Connection conn = DriverManager.getConnection(\"jdbc:postgresql://localhost/test\", \"user\", \"pass\");";;
      MySQL) snippet="Connection conn = DriverManager.getConnection(\"jdbc:mysql://localhost/test\", \"user\", \"pass\");";;
      SQLite) snippet="Connection conn = DriverManager.getConnection(\"jdbc:sqlite:sample.db\");";;
    esac
    ;;
  typescript)
    snippet="// Use appropriate library\n// PostgreSQL/MySQL: Sequelize, SQLite: sqlite3 or better-sqlite3"
    ;;
  go)
    snippet="// import database/sql & appropriate driver\nimport _ \"github.com/lib/pq\" // PostgreSQL example\ndb, err := sql.Open(\"postgres\", \"user=pq dbname=test sslmode=disable\")"
    ;;
  *)
    zenity --error --text="Unsupported language"; exit 1 ;;
esac

echo -e "$snippet"
