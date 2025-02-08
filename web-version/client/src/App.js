import React, { useState, useEffect } from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import axios from 'axios';
import Menu from './Menu';
import LoginForm from './LoginForm';
import Categories from './Categories';
import RegistrationForm from './RegisterForm';
import MyAccount from './MyAccount';
import Expenses from './Expenses';
import Settings from './Settings';
import Calendar from './Calendar';  // Import nowego komponentu Calendar
import './App.css';

const App = () => {
  const [loggedIn, setLoggedIn] = useState(false);
  const [userData, setUserData] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Sprawdzamy, czy użytkownik jest zalogowany przy każdym załadowaniu aplikacji
    axios.get('http://localhost:3000/user-data', { withCredentials: true })
      .then(response => {
        setUserData(response.data); // Ustawiamy dane użytkownika
        setLoggedIn(true);  // Użytkownik jest zalogowany
        setLoading(false);  // Zakończenie ładowania
      })
      .catch(error => {
        console.error('Brak aktywnej sesji:', error);  // Jeśli brak aktywnej sesji
        setLoggedIn(false); // Ustawienie stanu loggedIn na false
        setLoading(false);  // Zakończenie ładowania
      });
  }, []);  // Tylko raz po załadowaniu komponentu

  const handleLogin = (userData) => {
    setUserData(userData);
    setLoggedIn(true);  // Użytkownik zalogowany
  };

  const handleLogout = () => {
    axios.post('http://localhost:3000/logout', {}, { withCredentials: true })
      .then(() => {
        setLoggedIn(false);
        setUserData(null);  // Usuwamy dane użytkownika po wylogowaniu
      })
      .catch(error => {
        console.error('Błąd wylogowania', error);
      });
  };

  if (loading) {
    return <div>Ładowanie...</div>;
  }

  return (
    <Router>
      <div>
        {loggedIn && (window.location.pathname !== '/login' && window.location.pathname !== '/register') && (
          <Menu handleLogout={handleLogout} />
        )}
        <Routes>
          <Route path="/login" element={loggedIn ? <Navigate to="/" /> : <LoginForm handleLogin={handleLogin} />} />
          <Route path="/register" element={!loggedIn ? <RegistrationForm /> : <Navigate to="/" />} />
          <Route path="/account" element={loggedIn ? <MyAccount handleLogout={handleLogout} /> : <Navigate to="/login" />} />
          <Route path="/categories" element={loggedIn ? <Categories handleLogout={handleLogout} /> : <Navigate to="/login" />} />
          <Route path="/expenses" element={loggedIn ? <Expenses handleLogout={handleLogout} /> : <Navigate to="/login" />} />
          <Route path="/settings" element={loggedIn ? <Settings handleLogout={handleLogout} /> : <Navigate to="/login" />} />
          <Route path="/calendar" element={loggedIn ? <Calendar /> : <Navigate to="/login" />} /> {/* Nowa trasa */}
        </Routes>
      </div>
    </Router>
  );
};

export default App;
