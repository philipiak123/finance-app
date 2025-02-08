const express = require('express');
const bodyParser = require('body-parser');
const mysql = require('mysql');
const bcrypt = require('bcrypt');
const cors = require('cors');
const session = require('express-session');

const app = express();

// Middleware
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

app.use(cors({
  origin: 'http://localhost:5001', // Domena klienta (frontend)
  methods: ['GET', 'POST', 'OPTIONS', 'PUT', 'PATCH', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  credentials: true // Umożliwia przesyłanie ciasteczek (cookies) i danych uwierzytelniających
}));

// Konfiguracja sesji
app.use(session({
  secret: 'your_secret_key', // Użyj mocnego klucza
  resave: false, // Zapisuj sesję tylko, gdy dane się zmieniają
  saveUninitialized: false, // Nie zapisuj pustych sesji
  cookie: {
    httpOnly: true, // Zabezpieczenie przed dostępem do ciasteczek z poziomu JS
    secure: false, // Ustaw na true w środowisku produkcyjnym przy użyciu HTTPS
    sameSite: 'lax' // Chroni przed atakami CSRF
  }
}));

app.use(session({
  secret: 'fjsdhfis6gWwWwW', // Zmień na silniejszy klucz w produkcji
  resave: false,
  saveUninitialized: true,
  cookie: { secure: false } // Dla developmentu, w produkcji ustaw na true z HTTPS
}));

// Połączenie z bazą danych MySQL
const connection = mysql.createConnection({
  host: 'localhost',
  user: 'root',
  password: '',
  database: 'finance_app'
});

connection.connect((error) => {
  if (error) {
    console.error('Błąd połączenia z bazą danych MySQL:', error);
  } else {
    console.log('Połączono z bazą danych MySQL');
  }
});
app.post('/toggle_mode', async (req, res) => {
  const { userId } = req.body;
  
  if (!userId) {
    return res.status(400).json({ error: 'Brak ID użytkownika' }); // Zwracaj JSON w przypadku błędu
  }

  console.log(`Zmiana trybu dla użytkownika: ${userId}`);

  connection.query('SELECT mode FROM uzytkownicy WHERE id = ?', [userId], (error, results) => {
    if (error) {
      console.error('Błąd podczas pobierania trybu:', error);
      return res.status(500).json({ error: 'Wystąpił błąd podczas pobierania trybu' });
    }

    if (results.length === 0) {
      return res.status(404).json({ error: 'Użytkownik nie znaleziony' });
    }

    const currentMode = results[0].mode;
    const newMode = currentMode === 0 ? 1 : 0;
    console.log(`Obecny tryb: ${currentMode}, Nowy tryb: ${newMode}`);

    connection.query('UPDATE uzytkownicy SET mode = ? WHERE id = ?', [newMode, userId], (updateError) => {
      if (updateError) {
        console.error('Błąd podczas aktualizacji trybu:', updateError);
        return res.status(500).json({ error: 'Wystąpił błąd podczas aktualizacji trybu' });
      }

      // 🔹 Aktualizacja trybu w sesji użytkownika
      req.session.user.mode = newMode;

      req.session.save((sessionError) => {
        if (sessionError) {
          console.error('Błąd podczas zapisywania sesji:', sessionError);
          return res.status(500).json({ error: 'Błąd podczas zapisywania sesji' });
        }

        console.log('Tryb użytkownika zapisany w sesji:', req.session.user.mode);
        res.status(200).json({ newMode }); // Odpowiedź w formacie JSON
      });
    });
  });
});
app.post('/toggle_mode_mobile', async (req, res) => {
  const { userId } = req.body;
  
  if (!userId) {
    return res.status(400).json({ error: 'Brak ID użytkownika' }); // Zwracaj JSON w przypadku błędu
  }

  console.log(`Zmiana trybu dla użytkownika: ${userId}`);

  connection.query('SELECT mode FROM uzytkownicy WHERE id = ?', [userId], (error, results) => {
    if (error) {
      console.error('Błąd podczas pobierania trybu:', error);
      return res.status(500).json({ error: 'Wystąpił błąd podczas pobierania trybu' });
    }

    if (results.length === 0) {
      return res.status(404).json({ error: 'Użytkownik nie znaleziony' });
    }

    const currentMode = results[0].mode;
    const newMode = currentMode === 0 ? 1 : 0;
    console.log(`Obecny tryb: ${currentMode}, Nowy tryb: ${newMode}`);

    connection.query('UPDATE uzytkownicy SET mode = ? WHERE id = ?', [newMode, userId], (updateError) => {
      if (updateError) {
        console.error('Błąd podczas aktualizacji trybu:', updateError);
        return res.status(500).json({ error: 'Wystąpił błąd podczas aktualizacji trybu' });
      }

      // Tylko aktualizacja bazy danych, brak sesji
      console.log('Tryb użytkownika został zmieniony');
      res.status(200).json({ newMode }); // Odpowiedź w formacie JSON z nowym trybem
    });
  });
});



// Endpoint rejestracji
const insertQuery = 'INSERT INTO uzytkownicy (email, pass, mode) VALUES (?, ?, 0)';
const selectQuery = 'SELECT * FROM uzytkownicy WHERE email = ?';

app.post('/register', async (req, res) => {
  const { email, password } = req.body;

  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(email)) {
    return res.status(400).json({ error: 'Niepoprawny format adresu email.' });
  }

  const hashedPassword = await bcrypt.hash(password, 10);

  connection.query(selectQuery, [email], (selectErr, selectResults) => {
    if (selectErr) {
      console.error('Błąd podczas wyszukiwania użytkownika:', selectErr);
      return res.status(500).json({ error: 'Błąd serwera. Spróbuj ponownie później.' });
    }

    if (selectResults.length > 0) {
      return res.status(409).json({ error: 'Użytkownik o podanym adresie email już istnieje.' });
    }

    connection.query(insertQuery, [email, hashedPassword], (insertErr) => {
      if (insertErr) {
        console.error('Błąd zapisu nowego użytkownika do bazy danych:', insertErr);
        return res.status(500).json({ error: 'Błąd serwera. Spróbuj ponownie później.' });
      }
      return res.status(201).json({ message: 'Użytkownik został pomyślnie zarejestrowany.' });
    });
  });
});

app.post('/login', async (req, res) => {
  const { email, password } = req.body;
  console.log("dfgdfg");

  connection.query('SELECT * FROM uzytkownicy WHERE email = ?', [email], async (error, results) => {
    if (error) {
      console.error('Błąd podczas wyszukiwania użytkownika:', error);
      return res.status(500).send('Wystąpił błąd podczas logowania');
    }

    if (results.length > 0) {
      const user = results[0];
      if (await bcrypt.compare(password, user.pass)) {
        // Tworzymy sesję z danymi użytkownika
        req.session.user = {
          id: user.id,
          email: user.email,
          mode: user.mode
        };

        res.status(200).json({
          message: 'Zalogowano pomyślnie',
          user: { email: user.email, id: user.id, mode: user.mode }
        });
      } else {
        res.status(401).send('Błąd logowania');
      }
    } else {
      res.status(401).send('Błąd logowania');
    }
  });
});

// Endpoint /user-data, który zwróci dane sesji
app.get('/user-data', (req, res) => {
  if (req.session.user) {
    res.status(200).json(req.session.user);
  } else {
    res.status(401).json({ message: 'Brak aktywnej sesji. Zaloguj się, aby uzyskać dostęp.' });
  }
});

// Endpoint /logout, który zniszczy sesję
app.post('/logout', (req, res) => {
  req.session.destroy((err) => {
    if (err) {
      return res.status(500).json({ message: 'Błąd przy wylogowywaniu.' });
    }
    res.status(200).json({ message: 'Pomyślnie wylogowano.' });
  });
});


app.post('/add_category', (req, res) => {
  const { userId, name, color } = req.body;

  // Sprawdzenie czy kategoria o podanej nazwie lub kolorze już istnieje
  const checkQuery = 'SELECT * FROM kategorie WHERE user_id = ? AND (name = ? OR color = ?) LIMIT 1';

  connection.query(checkQuery, [userId, name, color], (checkError, checkResults) => {
    if (checkError) {
      console.error('Błąd sprawdzania kategorii:', checkError);
      res.status(500).json({ error: 'Błąd serwera. Spróbuj ponownie później.' });
    } else {
      if (checkResults.length > 0) {
        // Kategoria o podanej nazwie lub kolorze już istnieje
        res.status(400).json({ error: 'Kategoria o podanej nazwie lub kolorze już istnieje.' });
      } else {
        // Przygotowanie zapytania SQL do wstawienia nowej kategorii
        const insertQuery = 'INSERT INTO kategorie (user_id, name, color) VALUES (?, ?, ?)';

        // Wykonanie zapytania SQL w bazie danych
        connection.query(insertQuery, [userId, name, color], (insertError, insertResults) => {
          if (insertError) {
            console.error('Błąd dodawania kategorii:', insertError);
            res.status(500).json({ error: 'Błąd serwera. Spróbuj ponownie później.' });
          } else {
            // Kategoria została pomyślnie dodana
            res.status(200).json({ message: 'Kategoria została pomyślnie dodana.' });
          }
        });
      }
    }
  });
});
app.post('/update_category', (req, res) => {
  const { userId, categoryId, name, color } = req.body;
  console.log(color);

  // Sprawdzenie, czy użytkownik ma już kategorię o tej samej nazwie lub kolorze (ignorując bieżącą kategorię)
  const checkQuery = 'SELECT * FROM kategorie WHERE user_id = ? AND (name = ? OR color = ?) AND id != ? LIMIT 1';

  connection.query(checkQuery, [userId, name, color, categoryId], (checkError, checkResults) => {
    if (checkError) {
      console.error('Błąd sprawdzania kategorii:', checkError);
      res.status(500).json({ error: 'Błąd serwera. Spróbuj ponownie później.' });
    } else {
      if (checkResults.length > 0) {
        // Kategoria o podanej nazwie lub kolorze już istnieje
        res.status(400).json({ error: 'Kategoria o podanej nazwie lub kolorze już istnieje.' });
      } else {
        // Zapytanie SQL do aktualizacji kategorii
        const updateQuery = 'UPDATE kategorie SET name = ?, color = ? WHERE id = ?';

        // Wykonanie zapytania SQL w bazie danych
        connection.query(updateQuery, [name, color, categoryId], (error, results) => {
          if (error) {
            console.error('Błąd aktualizacji kategorii:', error);
            res.status(500).json({ error: 'Błąd serwera. Spróbuj ponownie później.' });
          } else {
            res.status(200).json({ message: 'Kategoria została zaktualizowana.' });
          }
        });
      }
    }
  });
});


app.get('/categories/:userId', (req, res) => {
  const userId = req.params.userId;

  // Zapytanie SQL do pobrania kategorii dla określonego użytkownika
  const selectQuery = 'SELECT * FROM kategorie WHERE user_id = ?';

  // Wykonanie zapytania SQL w bazie danych
  connection.query(selectQuery, [userId], (error, results) => {
    if (error) {
      console.error('Błąd pobierania kategorii:', error);
      res.status(500).json({ error: 'Błąd serwera. Spróbuj ponownie później.' });
    } else {
      // Zwrócenie listy kategorii
      res.status(200).json(results);
    }
  });
});

app.delete('/delete_category/:categoryId', (req, res) => {
  const categoryId = req.params.categoryId;

  // Usunięcie powiązanych wydatków (expenses) dla danej kategorii
  const deleteExpensesQuery = 'DELETE FROM expenses WHERE category_id = ?';
  connection.query(deleteExpensesQuery, [categoryId], (deleteExpensesError, deleteExpensesResults) => {
    if (deleteExpensesError) {
      console.error('Błąd usuwania wydatków:', deleteExpensesError);
      res.status(500).json({ error: 'Błąd serwera. Spróbuj ponownie później.' });
    } else {
      // Usunięcie samej kategorii po usunięciu wydatków
      const deleteCategoryQuery = 'DELETE FROM kategorie WHERE id = ?';
      connection.query(deleteCategoryQuery, [categoryId], (deleteCategoryError, deleteCategoryResults) => {
        if (deleteCategoryError) {
          console.error('Błąd usuwania kategorii:', deleteCategoryError);
          res.status(500).json({ error: 'Błąd serwera. Spróbuj ponownie później.' });
        } else {
          res.status(200).json({ message: 'Kategoria została pomyślnie usunięta.' });
        }
      });
    }
  });
});
// Endpoint do usuwania wydatku (metoda POST)
app.post('/delete_expense', (req, res) => {
  const { expenseId } = req.body;
  console.log(expenseId);

  // Zapytanie SQL do usunięcia wydatku
  const deleteExpenseQuery = 'DELETE FROM expenses WHERE id = ?';

  // Wykonanie zapytania SQL w bazie danych
  connection.query(deleteExpenseQuery, [expenseId], (error, results) => {
    if (error) {
      console.error('Błąd usuwania wydatku:', error);
      res.status(500).json({ error: 'Błąd serwera. Spróbuj ponownie później.' });
    } else {
      res.status(200).json({ message: 'Wydatek został pomyślnie usunięty.' });
    }
  });
});

// Endpoint do aktualizacji wydatku

app.post('/groups', (req, res) => {
  const { name, admin_id } = req.body;

  // Query to insert the new group
  const insertGroupQuery = 'INSERT INTO groups (name) VALUES (?)';

  connection.query(insertGroupQuery, [name], (insertGroupError, insertGroupResults) => {
    if (insertGroupError) {
      console.error('Błąd dodawania grupy:', insertGroupError);
      res.status(500).json({ error: 'Błąd serwera. Spróbuj ponownie później.' });
    } else {
      const groupId = insertGroupResults.insertId;
      // Query to insert the admin with all permissions set to TRUE
      const insertMemberQuery = `
        INSERT INTO members (
          group_id, user_id, admin,
          add_user, edit_user, delete_user,
          add_expense, edit_expense, delete_expense,
          add_category, edit_category, delete_category
        ) VALUES (?, ?, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE)`;

      connection.query(insertMemberQuery, [groupId, admin_id], (insertMemberError) => {
        if (insertMemberError) {
          console.error('Błąd dodawania administratora:', insertMemberError);
          res.status(500).json({ error: 'Błąd serwera. Spróbuj ponownie później.' });
        } else {
          res.status(200).json({ message: 'Grupa została pomyślnie dodana.' });
        }
      });
    }
  });
});
app.post('/add-user', (req, res) => {
  const { groupId, user_id, add_user, edit_user, delete_user, add_expense, edit_expense, delete_expense, add_category, edit_category, delete_category } = req.body;

  // Krok 1: Sprawdź, czy użytkownik już istnieje w grupie
  const checkUserQuery = 'SELECT * FROM members WHERE group_id = ? AND user_id = ?';

  connection.query(checkUserQuery, [groupId, user_id], (checkError, checkResults) => {
    if (checkError) {
      console.error('Błąd sprawdzania użytkownika:', checkError);
      res.status(500).json({ error: 'Błąd serwera. Spróbuj ponownie później.' });
    } else {
      if (checkResults.length > 0) {
        // Użytkownik już istnieje w grupie
        res.status(400).json({ error: 'Użytkownik o tym ID już istnieje w grupie.' });
      } else {
        // Krok 2: Dodaj użytkownika do grupy
        const insertMemberQuery = `
          INSERT INTO members (
            group_id, user_id, admin,
            add_user, edit_user, delete_user,
            add_expense, edit_expense, delete_expense,
            add_category, edit_category, delete_category
          ) VALUES (?, ?, FALSE, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        `;

        connection.query(insertMemberQuery, [
          groupId, user_id,
          add_user, edit_user, delete_user,
          add_expense, edit_expense, delete_expense,
          add_category, edit_category, delete_category
        ], (insertError) => {
          if (insertError) {
            console.error('Błąd dodawania użytkownika:', insertError);
            res.status(500).json({ error: 'Błąd serwera. Spróbuj ponownie później.' });
          } else {
            res.status(200).json({ message: 'Użytkownik został pomyślnie dodany do grupy.' });
          }
        });
      }
    }
  });
});


app.delete('/delete-user', (req, res) => {
  const { groupId, userId } = req.body;

  // Usuń użytkownika z grupy
  const deleteUserQuery = 'DELETE FROM members WHERE group_id = ? AND user_id = ?';

  connection.query(deleteUserQuery, [groupId, userId], (deleteUserError) => {
    if (deleteUserError) {
      console.error('Błąd usuwania użytkownika:', deleteUserError);
      res.status(500).json({ error: 'Błąd serwera. Spróbuj ponownie później.' });
    } else {
      res.status(200).json({ message: 'Użytkownik został pomyślnie usunięty z grupy.' });
    }
  });
});


// Endpoint do pobierania członków grupy
app.get('/groups/:groupId/members', (req, res) => {
  const { groupId } = req.params;

  const query = 'SELECT user_id, admin FROM members WHERE group_id = ?';
  connection.query(query, [groupId], (error, results) => {
    if (error) {
      console.error('Błąd podczas pobierania członków grupy:', error);
      res.status(500).json({ error: 'Błąd serwera. Spróbuj ponownie później.' });
    } else {
      res.status(200).json(results);
    }
  });
});

app.get('/users/:userId/groups', (req, res) => {
  const { userId } = req.params;

  const query = `
    SELECT g.id, g.name
    FROM groups g
    JOIN members m ON g.id = m.group_id
    WHERE m.user_id = ?
  `;

  connection.query(query, [userId], (error, results) => {
    if (error) {
      console.error('Błąd podczas pobierania grup użytkownika:', error);
      res.status(500).json({ error: 'Błąd serwera. Spróbuj ponownie później.' });
    } else {
      res.status(200).json(results);
    }
  });
});


app.post('/add_expense', (req, res) => {
  const { userId, categoryId, name, amount, date } = req.body;

  // Zapytanie SQL do dodania wydatku
  const insertQuery = 'INSERT INTO expenses (user_id, category_id, name, amount, date) VALUES (?, ?, ?, ?, ?)';

  // Wykonanie zapytania SQL w bazie danych
  connection.query(insertQuery, [userId, categoryId, name, amount, date], (error, results) => {
    if (error) {
      console.error('Błąd dodawania wydatku:', error);
      res.status(500).json({ error: 'Błąd serwera. Spróbuj ponownie później.' });
    } else {
      res.status(200).json({ message: 'Wydatek został pomyślnie dodany.' });
    }
  });
});
app.post('/update_password', async (req, res) => {
  const { userId, currentPassword, newPassword } = req.body;

  try {
    // Pobranie hasła użytkownika z bazy danych na podstawie userId
    const query = 'SELECT pass FROM uzytkownicy WHERE id = ?';
    connection.query(query, [userId], async (error, results, fields) => {
      if (error) {
        console.error('Błąd przy pobieraniu hasła użytkownika:', error);
        return res.status(500).json({ message: 'Wystąpił błąd podczas pobierania hasła.' });
      }

      // Sprawdzenie czy użytkownik istnieje
      if (results.length === 0) {
        return res.status(404).json({ message: 'Użytkownik nie istnieje.' });
      }

      const passwordHash = results[0].pass;

      // Porównanie podanego hasła obecnego z hasłem zapisanym w bazie danych
      const passwordMatch = await bcrypt.compare(currentPassword, passwordHash);

      if (!passwordMatch) {
        return res.status(401).json({ message: 'Podane obecne hasło jest niepoprawne.' });
      }

      // Haszowanie nowego hasła przed zapisaniem do bazy danych
      const saltRounds = 10;
      const hashedPassword = await bcrypt.hash(newPassword, saltRounds);

      // Aktualizacja hasła w bazie danych
      const updateQuery = 'UPDATE uzytkownicy SET pass = ? WHERE id = ?';
      connection.query(updateQuery, [hashedPassword, userId], (updateError, updateResults, updateFields) => {
        if (updateError) {
          console.error('Błąd przy aktualizacji hasła użytkownika:', updateError);
          return res.status(500).json({ message: 'Wystąpił błąd podczas aktualizacji hasła.' });
        }
        // Zwrócenie odpowiedzi sukcesu
        res.status(200).json({ message: 'Hasło zostało pomyślnie zmienione.' });
      });

    });
  } catch (error) {
    console.error('Wystąpił błąd:', error);
    res.status(500).json({ message: 'Wystąpił błąd podczas zmiany hasła.' });
  }
});
// Endpoint to fetch expenses for a specific user
app.get('/expenses/:userId', (req, res) => {
  const userId = req.params.userId;
console.log(userId);
  // SQL query to fetch expenses for the user
  const selectQuery = 'SELECT * FROM expenses WHERE user_id = ?';

  connection.query(selectQuery, [userId], (error, results) => {
    if (error) {
      console.error('Error fetching expenses:', error);
      res.status(500).json({ error: 'Server error. Please try again later.' });
    } else {
      res.status(200).json(results);
    }
  });
});

app.post('/update_expense', (req, res) => {
  const { userId, expenseId, name, amount, categoryId, date } = req.body;
  console.log(userId, expenseId, name, amount, categoryId, date);

  // Zapytanie SQL do aktualizacji wydatku
  const updateQuery = 'UPDATE expenses SET name = ?, amount = ?, category_id = ?, date = ? WHERE id = ?';

  // Wykonanie zapytania SQL w bazie danych
  connection.query(updateQuery, [name, amount, categoryId, date, expenseId], (error, results) => {
    if (error) {
      console.error('Błąd aktualizacji wydatku:', error);
      res.status(500).json({ error: 'Błąd serwera. Spróbuj ponownie później.' });
    } else {
      res.status(200).json({ message: 'Wydatek został zaktualizowany.' });
    }
  });
});
const PORT = 3000;
app.listen(PORT, () => {
  console.log(`Serwer uruchomiony na porcie ${PORT}`);
});
