CREATE TABLE IF NOT EXISTS users (
    id INT(6) NOT NULL AUTO_INCREMENT PRIMARY KEY,
    user VARCHAR(255) NOT NULL,
    pass VARCHAR(255) NOT NULL
);

CREATE TABLE IF NOT EXISTS news (
    id INT(6) NOT NULL AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    body VARCHAR(1024) NOT NULL
);

INSERT INTO users (user,pass) VALUES
    ("admin", "very-secret-pass"),
    ("i4k", "****************"),
    ("katz", "i love alan kay");

INSERT INTO news (title,body) VALUES
    (
        "BITCOIN FALLS BELOW $38,000 AS EVERGROW SET TO BREAK NEW CRYPTO RECORDS",
        "Bitcoin price has fallen to below $38,000 for the second time in 2022. Cryptocurrency largest token has struggled since starting the year at $47,000 and despite a rally in early February Bitcoin price is back where it was a month ago. A combination of factors means that investors are increasingly avoiding risk, and in the current climate risk means Bitcoin."
    ),
    (
        "Russia retreats from crypto ban as it pushes rules for industry",
        "Russias Ministry of Finance is planning to regulate cryptocurrencies in the country, despite earlier calls by the central bank for a ban on crypto."
    );