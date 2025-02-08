import React, { useState, useEffect } from 'react';
import axios from 'axios';
import './Categories.css';

const Categories = () => {
  const [userData, setUserData] = useState(null);
  const [categories, setCategories] = useState([]);
  const [editingCategory, setEditingCategory] = useState(null);
  const [editedName, setEditedName] = useState('');
  const [editedColor, setEditedColor] = useState('');
  const [newName, setNewName] = useState('');
  const [newColor, setNewColor] = useState('#000000');
  const [successMessage, setSuccessMessage] = useState('');
  const [errorMessage, setErrorMessage] = useState('');
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [isErrorModalOpen, setIsErrorModalOpen] = useState(false);
  const [isAddModalOpen, setIsAddModalOpen] = useState(false);

  useEffect(() => {
    const fetchUserData = async () => {
      try {
        const response = await axios.get('http://localhost:3000/user-data', { withCredentials: true });
        setUserData(response.data);

console.log(response.data);
if (response.data.mode === 1) {
  document.body.classList.add('dark-theme');
} else {
  document.body.classList.remove('dark-theme'); // Dodaj to, aby usunąć tryb ciemny
}

      } catch (error) {
        console.error('Błąd podczas pobierania danych użytkownika:', error);
      }
    };

    fetchUserData();
  }, []);

  useEffect(() => {
    const fetchCategories = async () => {
      if (userData && userData.id) {
        try {
          const response = await axios.get(`http://localhost:3000/categories/${userData.id}`, { withCredentials: true });
          setCategories(response.data);
        } catch (error) {
          console.error('Błąd podczas pobierania kategorii:', error);
        }
      }
    };

    if (userData && userData.id) {
      fetchCategories();
    }
  }, [userData]);

  const handleEditCategory = (categoryId) => {
    const categoryToEdit = categories.find((category) => category.id === categoryId);
    setEditingCategory(categoryId);
    setEditedName(categoryToEdit.name);
    setEditedColor(`#${categoryToEdit.color}`);
    setIsModalOpen(true);
  };

  const formattedColor = editedColor.startsWith('#') ? editedColor.slice(1) : editedColor;

  const handleSaveEdit = async () => {
    try {
      await axios.post(
        'http://localhost:3000/update_category',
        {
          userId: userData.id,
          categoryId: editingCategory,
          name: editedName,
          color: formattedColor,
        },
        { withCredentials: true }
      );

      setCategories((prevCategories) =>
        prevCategories.map((category) =>
          category.id === editingCategory
            ? { ...category, name: editedName, color: formattedColor }
            : category
        )
      );

      setEditingCategory(null);
      setEditedName('');
      setEditedColor('');
      setSuccessMessage('Kategoria została zaktualizowana.');
      setIsModalOpen(false);
    } catch (error) {
      setErrorMessage('Błąd podczas zapisywania edycji kategorii.');
      setIsErrorModalOpen(true);
    }
  };

  const handleCancelEdit = () => {
    setEditingCategory(null);
    setEditedName('');
    setEditedColor('');
    setSuccessMessage('');
    setErrorMessage('');
    setIsModalOpen(false);
  };

  const handleCloseErrorModal = () => {
    setErrorMessage('');
    setIsErrorModalOpen(false);
  };

  const handleAddCategory = async () => {
    try {
      const response = await axios.post(
        'http://localhost:3000/add_category',
        {
          userId: userData.id,
          name: newName,
          color: newColor.slice(1),
        },
        { withCredentials: true }
      );

      setCategories([...categories, { id: response.data.id, name: newName, color: newColor.slice(1) }]);

      setNewName('');
      setNewColor('#000000');
      setSuccessMessage('Kategoria została dodana.');
      setIsAddModalOpen(false);
    } catch (error) {
      setErrorMessage('Błąd podczas dodawania kategorii.');
      setIsErrorModalOpen(true);
    }
  };

  const handleDeleteCategory = async (categoryId) => {
    try {
      await axios.delete(`http://localhost:3000/delete_category/${categoryId}`, {
        withCredentials: true,
      });

      setCategories(categories.filter((category) => category.id !== categoryId));
      setSuccessMessage('Kategoria została usunięta.');
    } catch (error) {
      setErrorMessage('Błąd podczas usuwania kategorii.');
      setIsErrorModalOpen(true);
    }
  };

  return (
    <div className={`categories ${userData?.mode === 1 ? 'dark-mode' : ''}`}>
      <h2>Kategorie użytkownika: {userData ? userData.name : '...'}</h2>
      <button className="add-button" onClick={() => setIsAddModalOpen(true)}>Dodaj kategorię</button>
      
      {successMessage && (
        <div className="success-message">
          <p>{successMessage}</p>
          <button className="close-button" onClick={() => setSuccessMessage('')}>Zamknij</button>
        </div>
      )}
      
      <div className="categories-list">
        {categories.map(category => (
          <div key={category.id} className="category-item">
            <div className="category-color" style={{ backgroundColor: `#${category.color}` }}></div>
            <p className="category-name">{category.name}</p>
            <div className="category-buttons">
              <button className="edit-button" onClick={() => handleEditCategory(category.id)}>Edytuj</button>
              <button className="delete-button" onClick={() => handleDeleteCategory(category.id)}>Usuń</button>
            </div>
          </div>
        ))}
      </div>

      {isModalOpen && (
        <div className="modal-overlay dark-mode">
          <div className="modal dark-mode">
            <h2>Edytuj kategorię</h2>
            <input type="text" value={editedName} onChange={(e) => setEditedName(e.target.value)} />
            <input type="color" value={editedColor} onChange={(e) => setEditedColor(e.target.value)} />
            <button onClick={handleSaveEdit}>Zapisz</button>
            <button onClick={handleCancelEdit}>Anuluj</button>
          </div>
        </div>
      )}

      {isAddModalOpen && (
        <div className="modal-overlay dark-mode">
          <div className="modal dark-mode">
            <h2>Dodaj nową kategorię</h2>
            <input type="text" value={newName} onChange={(e) => setNewName(e.target.value)} placeholder="Nazwa kategorii" />
            <input type="color" value={newColor} onChange={(e) => setNewColor(e.target.value)} />
            <button onClick={handleAddCategory}>Dodaj</button>
            <button onClick={() => setIsAddModalOpen(false)}>Anuluj</button>
          </div>
        </div>
      )}

      {isErrorModalOpen && (
        <div className="modal-overlay dark-mode">
          <div className="modal dark-mode">
            <h2>Błąd</h2>
            <p>{errorMessage}</p>
            <button onClick={handleCloseErrorModal}>Zamknij</button>
          </div>
        </div>
      )}
    </div>
  );
};

export default Categories;
