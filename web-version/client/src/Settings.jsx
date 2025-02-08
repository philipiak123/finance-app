import React, { useState, useEffect } from 'react';
import axios from 'axios';
import './Settings.css';

const Settings = () => {
  const [userData, setUserData] = useState(null);
  const [message, setMessage] = useState('');

  // Pobranie danych użytkownika przy załadowaniu komponentu
  useEffect(() => {
    const fetchUserData = async () => {
      try {
        const response = await axios.get('http://localhost:3000/user-data', { withCredentials: true });
        setUserData(response.data);
      } catch (error) {
        console.error('Błąd podczas pobierania danych użytkownika:', error);
        setMessage('Błąd podczas pobierania danych użytkownika.');
      }
    };

    fetchUserData();
  }, []);

  // Zaktualizowanie trybu w body po załadowaniu danych użytkownika
  useEffect(() => {
    if (userData) {
      if (userData.mode === 1) {
        document.body.classList.add('dark-mode');
      } else {
        document.body.classList.remove('dark-mode');
      }
    }
  }, [userData]); // Reakcja na zmianę danych użytkownika

  const handleToggleMode = async () => {
    if (!userData || !userData.id) {
      setMessage('Błąd: Brak ID użytkownika.');
      return;
    }

    try {
      const response = await axios.post(
        'http://localhost:3000/toggle_mode',
        { userId: userData.id },
        { withCredentials: true }
      );

      const newMode = response.data.newMode;

      // Aktualizacja trybu użytkownika w stanie
      setUserData((prev) => ({ ...prev, mode: newMode }));

      setMessage('Tryb zaktualizowany pomyślnie');
    } catch (error) {
      console.error('Błąd podczas aktualizacji trybu:', error);
      setMessage('Błąd podczas aktualizacji trybu');
    }
  };

  if (!userData) {
    return <p>Ładowanie danych...</p>;
  }

  return (
    <div className={`settings ${userData.mode === 1 ? 'dark-mode' : 'light-mode'}`}>
      <h2>Ustawienia</h2>
      {message && <div>{message}</div>}
      <div>
        <button onClick={handleToggleMode}>Zmień tryb</button>
      </div>
    </div>
  );
};

export default Settings;
