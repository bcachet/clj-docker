(ns exo.main
  (:require [exo.add :refer [sum]])
  (:gen-class))

(defn -main
  [& args]
  (println (format "Result: %d" (apply sum (map #(Integer/parseInt %) args))))
  (System/exit 0))