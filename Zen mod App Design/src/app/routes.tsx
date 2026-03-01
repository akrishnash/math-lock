import { createBrowserRouter } from "react-router";
import { Dashboard } from "./components/Dashboard";
import { Intervention } from "./components/Intervention";
import { MathChallenge } from "./components/MathChallenge";
import { Settings } from "./components/Settings";

export const router = createBrowserRouter([
  {
    path: "/",
    Component: Dashboard,
  },
  {
    path: "/intervention",
    Component: Intervention,
  },
  {
    path: "/challenge",
    Component: MathChallenge,
  },
  {
    path: "/settings",
    Component: Settings,
  },
]);