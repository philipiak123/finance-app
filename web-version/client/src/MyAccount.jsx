import React, { useState, useEffect } from 'react';
import axios from 'axios';
import './MyAccount.css';

const MyAccount = () => {
  const [userData, setUserData] = useState(null);
  const [email, setEmail] = useState('');
  const [message, setMessage] = useState('');
  const [isPasswordPopupOpen, setIsPasswordPopupOpen] = useState(false);
  const [currentPassword, setCurrentPassword] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');

  // Pobranie danych użytkownika
  useEffect(() => {
    const fetchUserData = async () => {
      try {
        const response = await axios.get('http://localhost:3000/user-data', { withCredentials: true });
        setUserData(response.data);
        setEmail(response.data.email);
      } catch (error) {
        console.error('Błąd podczas pobierania danych użytkownika:', error);
        setMessage('Błąd podczas pobierania danych użytkownika.');
      }
    };

    fetchUserData();
  }, []);

  const handlePasswordChange = (e) => {
    const { name, value } = e.target;
    if (name === 'currentPassword') {
      setCurrentPassword(value);
    } else if (name === 'newPassword') {
      setNewPassword(value);
    } else if (name === 'confirmPassword') {
      setConfirmPassword(value);
    }
  };

  const handlePasswordSubmit = async (e) => {
    e.preventDefault();
    if (newPassword !== confirmPassword) {
      setMessage('Nowe hasło i potwierdzenie hasła nie są zgodne');
      return;
    }

    try {
      const response = await axios.post('http://localhost:3000/changepass', {
        userId: userData.id,
        currentPassword,
        newPassword,
      });

      if (response.status === 200) {
        setMessage('Hasło zostało zmienione');
        handleClosePasswordPopup();
      } else {
        setMessage('Nieoczekiwany błąd podczas zmiany hasła');
        console.error('Błąd:', response);
      }
    } catch (error) {
      if (error.response && error.response.status === 400) {
        setMessage('Podane obecne hasło jest niepoprawne');
      } else if (error.response && error.response.status === 500) {
        setMessage('Błąd serwera. Spróbuj ponownie później.');
      } else {
        setMessage('Nieoczekiwany błąd podczas zmiany hasła');
        console.error('Błąd:', error);
      }
    }
  };

  const handleOpenPasswordPopup = () => {
    setIsPasswordPopupOpen(true);
  };

  const handleClosePasswordPopup = () => {
    setIsPasswordPopupOpen(false);
    setCurrentPassword('');
    setNewPassword('');
    setConfirmPassword('');
    setMessage('');
  };

  if (!userData) {
    return <p>Ładowanie danych...</p>;
  }

  return (
    <div className={`my-account ${userData.mode === 1 ? 'dark-mode' : 'light-mode'}`}>
      <h2>Moje Konto</h2>
      <div className="account-details">
        <p><strong>Email:</strong> {email}</p>
        <button onClick={handleOpenPasswordPopup} className="change-password-button">Zmień hasło</button>
      </div>

      {/* Popup zmiany hasła */}
{isPasswordPopupOpen && (
  <div className={`password-popup ${userData.mode === 1 ? 'dark-mode' : ''}`}>
    <div className={`password-popup-content ${userData.mode === 1 ? 'dark-mode' : ''}`}>
      <h2>Zmień hasło</h2>
      <form onSubmit={handlePasswordSubmit}>
        <div className="form-group">
          <label htmlFor="currentPassword">Obecne hasło:</label>
          <input
            type="password"
            id="currentPassword"
            name="currentPassword"
            value={currentPassword}
            onChange={handlePasswordChange}
          />
        </div>
        <div className="form-group">
          <label htmlFor="newPassword">Nowe hasło:</label>
          <input
            type="password"
            id="newPassword"
            name="newPassword"
            value={newPassword}
            onChange={handlePasswordChange}
          />
        </div>
        <div className="form-group">
          <label htmlFor="confirmPassword">Potwierdź hasło:</label>
          <input
            type="password"
            id="confirmPassword"
            name="confirmPassword"
            value={confirmPassword}
            onChange={handlePasswordChange}
          />
        </div>
        <button type="submit" className="update-password-button">Zmień hasło</button>
        {message && <p className="message">{message}</p>}
      </form>
      <button onClick={handleClosePasswordPopup} className="close-popup-button">Zamknij</button>
    </div>
  </div>
)}

    </div>
  );
};

export default MyAccount;
