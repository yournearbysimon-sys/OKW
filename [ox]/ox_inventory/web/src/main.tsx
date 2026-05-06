import React from 'react';
import { createRoot } from 'react-dom/client';
import { Provider } from 'react-redux';
import { DndProvider } from 'react-dnd';
import { TouchBackend } from 'react-dnd-touch-backend';
import { store } from './store';
import App from './App';
import './index.css';
import { ItemNotificationsProvider } from './components/utils/ItemNotifications';
import { isEnvBrowser } from './utils/misc';
import { InventorySettingsProvider } from './components/settings/InventorySettingsContext';

const root = document.getElementById('root');

if (isEnvBrowser()) {
  // https://i.imgur.com/iPTAdYV.png - Night time img
  // https://i.imgur.com/3pzRj9n.png - Day time img
  root!.style.backgroundImage =
    'url("https://cdn.discordapp.com/attachments/1457082530451816619/1463794194509336648/image.png?ex=69b1bf53&is=69b06dd3&hm=30c878c24599b06bc1ff896708a50fd835b19b680981eb2ac3e9ac758d61af27&")';
  root!.style.backgroundSize = 'cover';
  root!.style.backgroundRepeat = 'no-repeat';
  root!.style.backgroundPosition = 'center';
}

createRoot(root!).render(
  <React.StrictMode>
    <Provider store={store}>
      <DndProvider backend={TouchBackend} options={{ enableMouseEvents: true }}>
        <InventorySettingsProvider>
          <ItemNotificationsProvider>
            <App />
          </ItemNotificationsProvider>
        </InventorySettingsProvider>
      </DndProvider>
    </Provider>
  </React.StrictMode>
);
