from cog import BasePredictor, Input
from transformers import AutoModelForCausalLM, AutoTokenizer
import os

class Predictor(BasePredictor):
    def setup(self) -> None:
        """Load the model into memory to make running multiple predictions efficient"""
        model_path = os.getenv("MODEL_PATH", "../../") # locally the model is in the root directory
        self.tokenizer = AutoTokenizer.from_pretrained(model_path)
        self.model = AutoModelForCausalLM.from_pretrained(
            model_path,
            device_map="auto",  # Automatically distributes across available GPUs or uses CPU
            trust_remote_code=True
        )

    def predict(
        self,
        prompt: str = Input(description="Ask the LLM a question"),
    ) -> str:
        """Run a single prediction on the model"""
        inputs = self.tokenizer(prompt, return_tensors="pt", padding=True).to(self.model.device)

        outputs = self.model.generate(
            input_ids=inputs.input_ids,
            max_length=100,
            do_sample=True,
            top_p=0.95,
            temperature=0.3,
            attention_mask=inputs.attention_mask
        )

        response = self.tokenizer.decode(outputs[0], skip_special_tokens=True)
        return response