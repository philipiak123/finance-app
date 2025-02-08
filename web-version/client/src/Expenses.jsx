import React, { useState, useEffect, useRef } from 'react';
import axios from 'axios';
import './Expenses.css';
import { Doughnut } from 'react-chartjs-2';
import Chart from 'chart.js/auto';

const Expenses = () => {
  const [expenses, setExpenses] = useState([]);
  const [categories, setCategories] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [isAddModalOpen, setIsAddModalOpen] = useState(false);
  const [isEditModalOpen, setIsEditModalOpen] = useState(false);
  const [newExpense, setNewExpense] = useState({ name: '', amount: '', categoryId: '0', date: '' });
  const [editExpense, setEditExpense] = useState({ id: '', name: '', amount: '', categoryId: '0', date: '' });
  const [successMessage, setSuccessMessage] = useState('');
  const [validationError, setValidationError] = useState('');
  const [chartData, setChartData] = useState(null);
  const [sortBy, setSortBy] = useState('date'); // Domyślne sortowanie po dacie
  const [sortOrder, setSortOrder] = useState('desc'); // Domyślne sortowanie malejąco
  const chartRef = useRef(null);
  const chartInstanceRef = useRef(null);
const [userData, setUserData] = useState(null);

  useEffect(() => {
    const fetchExpensesAndCategories = async () => {
      try {
        const expensesResponse = await axios.get(`http://localhost:3000/expenses/${userData.id}`);
        const categoriesResponse = await axios.get(`http://localhost:3000/categories/${userData.id}`);
        setExpenses(expensesResponse.data);
        setCategories(categoriesResponse.data);
      } catch (error) {
        console.error('Error fetching data:', error);
      } finally {
        setLoading(false);
      }
    };

    fetchExpensesAndCategories();
  }, [userData]);

  useEffect(() => {
    if (categories.length && expenses.length) {
      generateChartData(categories, expenses);
    }
  }, [categories, expenses]);
useEffect(() => {
  const fetchUserData = async () => {
    try {
      const response = await axios.get('http://localhost:3000/user-data', {
        withCredentials: true, // Ważne, aby umożliwić dostęp do ciasteczek sesyjnych
      });
      setUserData(response.data); // Ustaw dane użytkownika w stanie
    } catch (error) {
      console.error('Error fetching user data:', error);
      setError('Błąd pobierania danych użytkownika');
    }
  };

  fetchUserData();
}, []);

  useEffect(() => {
    // Sortowanie danych na podstawie wybranych opcji
    const sortedExpenses = [...expenses].sort((a, b) => {
      const aValue = a[sortBy];
      const bValue = b[sortBy];

      if (sortBy === 'amount' || sortBy === 'id') {
        // Sortowanie liczb
        return sortOrder === 'asc' ? aValue - bValue : bValue - aValue;
      } else {
        // Sortowanie dat i tekstów
        return sortOrder === 'asc' ? aValue.localeCompare(bValue) : bValue.localeCompare(aValue);
      }
    });

    setExpenses(sortedExpenses);
  }, [sortBy, sortOrder]);

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setNewExpense({ ...newExpense, [name]: value });
  };

  const handleAddExpense = async () => {
    if (newExpense.categoryId === '0') {
      setValidationError('Wybierz kategorię.');
      return;
    }
    if (!newExpense.date) {
      setValidationError('Wybierz datę.');
      return;
    }
    const amount = newExpense.amount.replace(',', '.'); // Zamiana przecinka na kropkę

    if (parseFloat(amount) <= 1) {
      setValidationError('Kwota wydatku musi być większa niż jeden.');
      return;
    }

    try {
      const response = await axios.post('http://localhost:3000/add_expense', {
        userId: userData.id,
        ...newExpense,
        amount: parseFloat(amount)
      });

      setSuccessMessage(response.data.message);
      setTimeout(() => setSuccessMessage(''), 3000);


    } catch (error) {
      console.error('Error adding expense:', error);
      setError('Błąd serwera. Spróbuj ponownie później.');
    }
  };

  const handleEditInputChange = (e) => {
    const { name, value } = e.target;
    setEditExpense({ ...editExpense, [name]: value });
  };

  const handleEditExpense = async () => {
    if (editExpense.categoryId === '0') {
      setValidationError('Wybierz kategorię.');
      return;
    }
    if (!editExpense.date) {
      setValidationError('Wybierz datę.');
      return;
    }
    const amount = editExpense.amount.toString().replace(',', '.');

    if (parseFloat(amount) <= 1) {
      setValidationError('Kwota wydatku musi być większa niż jeden.');
      return;
    }

    try {
      const response = await axios.post('http://localhost:3000/update_expense', {
        userId: userData.id,
        expenseId: editExpense.id,
        ...editExpense,
        categoryId: parseInt(editExpense.categoryId),
        amount: parseFloat(amount)
      });

      setSuccessMessage(response.data.message);
      setTimeout(() => setSuccessMessage(''), 3000);

      window.location.reload(); // Odśwież stronę po edytowaniu wydatku

    } catch (error) {
      console.error('Error updating expense:', error);
      setError('Błąd serwera. Spróbuj ponownie później.');
    }
  };

  const handleDeleteExpense = async (expenseId) => {
    try {
      const response = await axios.post('http://localhost:3000/delete_expense', { expenseId });
      setSuccessMessage(response.data.message);
      setTimeout(() => setSuccessMessage(''), 3000);

      window.location.reload(); // Odśwież stronę po usunięciu wydatku

    } catch (error) {
      console.error('Error deleting expense:', error);
      setError('Błąd serwera. Spróbuj ponownie później.');
    }
  };

  const openEditModal = (expense) => {
    setEditExpense({
      id: expense.id,
      name: expense.name,
      amount: expense.amount.toString(), // Ensure amount is a string
      categoryId: expense.category_id, // Ensure category_id is correctly mapped
      date: expense.date
    });
    setIsEditModalOpen(true);
  };

  const generateChartData = (categoriesData, expensesData) => {
    const categoryNames = categoriesData.map(category => category.name);
    const categoryAmounts = categoriesData.map(category =>
      expensesData.filter(expense => expense.category_id === category.id)
        .reduce((total, expense) => total + parseFloat(expense.amount), 0)
    );

    const totalAmount = categoryAmounts.reduce((total, amount) => total + amount, 0);

    const chartData = {
      labels: categoryNames,
      datasets: [
        {
          data: categoryAmounts,
          backgroundColor: categoriesData.map(category => `#${category.color}`),
          hoverBackgroundColor: categoriesData.map(category => `#${category.color}`),
          borderWidth: 1 // Zmniejsz grubość wykresu
        }
      ]
    };

    if (chartInstanceRef.current) {
      chartInstanceRef.current.destroy();
    }

    chartInstanceRef.current = new Chart(chartRef.current, {
      type: 'doughnut',
      data: chartData,
      options: {
        cutout: '80%', // Zwiększenie rozmiaru wycięcia
        plugins: {
          tooltip: {
            callbacks: {
              label: (context) => {
                const label = context.label || '';
                const value = context.raw || 0;
                return `${label}: ${value.toFixed(2)} zł`;
              }
            }
          }
        }
      },
      plugins: [centerTextPlugin(totalAmount)]
    });
  };

  const centerTextPlugin = (totalAmount) => {
    return {
      id: 'centerText',
      beforeDraw: (chart) => {
        const { ctx, width, height } = chart;
        ctx.restore();
        const fontSize = (height / 150).toFixed(2); // Zmniejszenie czcionki
        ctx.font = `${fontSize}em sans-serif`;
        ctx.textBaseline = 'middle';
        const text = `${totalAmount.toFixed(2)} zł`;
        const textX = Math.round((width - ctx.measureText(text).width) / 2);
        const textY = height / 2;
        ctx.fillStyle = userData.mode === 1 ? '#fff' : '#000'; // Zmieniono na białą w trybie ciemnym
        ctx.fillText(text, textX, textY);
        ctx.save();
      }
    };
  };

  const handleSortChange = (e) => {
    const { value } = e.target;
    const [sortByValue, sortOrderValue] = value.split('-');
    setSortBy(sortByValue);
    setSortOrder(sortOrderValue);
  };

  return (
    <div className={`expenses ${userData?.mode === 1 ? 'dark-mode' : ''}`}>
      <h2>Wydatki użytkownika</h2>
      {error && <div className="error-message">{error}</div>}
      {successMessage && (
        <div className="success-message">
          {successMessage}
          <button className="close-button" onClick={() => setSuccessMessage('')}>Zamknij</button>
        </div>
      )}
      <button onClick={() => setIsAddModalOpen(true)} className="add-expense-button">Dodaj wydatek</button>
      <div className="sort-options">
        <label htmlFor="sort">Sortuj według:</label>
        <select id="sort" onChange={handleSortChange} value={`${sortBy}-${sortOrder}`}>
          <option value="date-desc">Data (malejąco)</option>
          <option value="date-asc">Data (rosnąco)</option>
          <option value="name-asc">Nazwa (A-Z)</option>
          <option value="name-desc">Nazwa (Z-A)</option>
          <option value="amount-desc">Wielkość wydatku (malejąco)</option>
          <option value="amount-asc">Wielkość wydatku (rosnąco)</option>
        </select>
      </div>
      <ul className="expenses-list">
        {expenses.map(expense => (
          <li key={expense.id}>
            {expense.name}: {expense.amount} zł
            <div>Data: {new Date(expense.date).toLocaleDateString()}</div>
            <div>
              <button className="edit-button" onClick={() => openEditModal(expense)}>Edytuj</button>
              <button className="delete-button" onClick={() => handleDeleteExpense(expense.id)}>Usuń</button>
            </div>
          </li>
        ))}
      </ul>

      <div className="chart-container">
        <canvas ref={chartRef} />
      </div>

      {isAddModalOpen && (
        <div className="modal-overlay">
          <div className={`modal ${userData.mode === 1 ? 'dark-modal' : ''}`}>
            <h2>Dodaj nowy wydatek</h2>
            {validationError && <div className="error-message">{validationError}</div>}
            <input
              type="text"
              name="name"
              placeholder="Nazwa wydatku"
              value={newExpense.name}
              onChange={handleInputChange}
            />
            <input
              type="number"
              name="amount"
              placeholder="Kwota"
			  min="0.01"
              value={newExpense.amount}
              onChange={handleInputChange}
            />
            <select
              name="categoryId"
              value={newExpense.categoryId}
              onChange={handleInputChange}
            >
              <option value="0">Wybierz kategorię</option>
              {categories.map(category => (
                <option key={category.id} value={category.id}>
                  {category.name}
                </option>
              ))}
            </select>
            <input
              type="date"
              name="date"
              value={newExpense.date}
              onChange={handleInputChange}
            />
            <button onClick={handleAddExpense}>Dodaj</button>
            <button onClick={() => setIsAddModalOpen(false)}>Anuluj</button>
          </div>
        </div>
      )}

      {isEditModalOpen && (
        <div className="modal-overlay">
          <div className={`modal ${userData.mode === 1 ? 'dark-modal' : ''}`}>
            <h2>Edytuj wydatek</h2>
            {validationError && <div className="error-message">{validationError}</div>}
            <input
              type="text"
              name="name"
              placeholder="Nazwa wydatku"
              value={editExpense.name}
              onChange={handleEditInputChange}
            />
            <input
              type="number"
              name="amount"
              placeholder="Kwota"
			  min="0.01"
              value={editExpense.amount}
              onChange={handleEditInputChange}
            />
            <select
              name="categoryId"
              value={editExpense.categoryId}
              onChange={handleEditInputChange}
            >
              {categories.map(category => (
                <option key={category.id} value={category.id}>
                  {category.name}
                </option>
              ))}
            </select>
            <input
              type="date"
              name="date"
              value={editExpense.date}
              onChange={handleEditInputChange}
            />
            <button onClick={handleEditExpense}>Zaktualizuj</button>
            <button onClick={() => setIsEditModalOpen(false)}>Anuluj</button>
          </div>
        </div>
      )}
    </div>
  );
};

export default Expenses;
