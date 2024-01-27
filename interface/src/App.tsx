import { BrowserRouter, Route, Routes } from "react-router-dom";
import "./App.css";
import Header from "./components/Header";
import { ProjectPage } from "./pages/ProjectPage/ProjectPage";

function App() {
  return (
    <BrowserRouter>
      <Header />
      <Routes>
        <Route element={<ProjectPage />} path="projects" />
      </Routes>
    </BrowserRouter>
  );
}

export default App;
