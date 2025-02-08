import React from 'react';
import { Link } from 'react-router-dom';
import './Menu.css';

const Menu = ({ handleLogout }) => {
  return (
    <nav className="menu">
      <ul>
        <li><Link to="/account">Konto</Link></li>
        <li><Link to="/categories">Kategorie</Link></li>
        <li><Link to="/expenses">Wydatki</Link></li>
		<li><Link to="/settings">Ustawienia</Link></li>
        <li><button onClick={handleLogout} className="logout-button">Wyloguj</button></li>
      </ul>
    </nav>
  );
};

export default Menu;
